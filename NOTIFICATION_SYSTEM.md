# Система уведомлений SannyBunnies

## Архитектура

Система уведомлений использует три уровня:
1. **Firebase Cloud Messaging (FCM)** — backend для отправки push-уведомлений
2. **Cloud Functions** — backend на Node.js для автоматической отправки уведомлений на события в Firestore
3. **Flutter app** — подписка на топики и локальное отображение уведомлений

## Топики подписки

Приложение использует следующие топики:

### Глобальные топики
- `general` — всем пользователям
- `parents` — всем родителям (если `notificationsEnabled: true`)
- `teachers` — всем учителям (если `notificationsEnabled: true`)

### Персональные топики
- `user_{uid}` — конкретному пользователю

### Групповые топики
- `group_{groupId}` — всем в группе

## Коллекции Firestore

```
users/
  {uid}
    uid: string
    name: string
    email: string
    phone: string
    role: 'user' | 'teacher'
    notificationsEnabled: boolean
    photoUrl: string?
    createdAt: timestamp
    platform: 'email' | 'google'

children/
  {childId}
    parent_uid: string
    group_id: string?
    name: string
    photoUrl: string?
    status: string
    mood: string
    temperature: number?
    absent: boolean
    requestStatus: boolean | null
    requestedAt: timestamp
    createdAt: timestamp

groups/
  {groupId}
    name: string
    age_from: number
    age_to: number
    teacher_uids: string[]  // uid учителей в группе
    children_uids: string[] // uid детей в группе

news/
  {newsId}
    title: string
    shortText: string?
    description: string?
    createdAt: timestamp

schedule/
  {scheduleId}
    group_id: string
    title: string
    createdAt: timestamp

kindergarten/
  info
    address: string
    phone: string
    ...
```

## Поток подписок

### 1. При регистрации (Login)
```
signUpWithEmail() или completeGoogleProfile()
  → создание документа users с notificationsEnabled: true
  → NotificationTopicService.updateSubscriptions()
    → подписка на: general, parents, user_{uid}
```

### 2. При входе (AuthWrapper)
```
authStateChanges() срабатывает
  → _configureTopics() вызывается
    → загружаются групpy (или дети для родителей)
    → NotificationTopicService.updateSubscriptions() вызывается
    → подписка на: general, parents|teachers, user_{uid}, group_*
```

### 3. При изменении уведомлений (Settings)
```
_toggleNotifications(bool value)
  → обновление notificationsEnabled в Firestore
  → NotificationTopicService.updateSubscriptions(enabled: value)
    → если value=false: отписка от всех топиков
    → если value=true: подписка на все топики для этого пользователя
```

## Cloud Functions события

### onNewsCreated
Когда создана новая новость:
```
Топики: general, parents
Сообщение: "[Заголовок новости]"
```

### onScheduleChanged
Когда обновлено расписание:
```
Топики: group_{groupId}
Сообщение: "Расписание [название] изменено для вашей группы."
```

### onChildUpdated
Когда обновлены данные ребёнка:
```
Если изменился requestStatus:
  → Топики: teachers, group_{groupId}
  → Сообщение: "[Имя ребёнка]: заявка {создана|отменена|принята}"

Если изменился статус/настроение/температура/отсутствие:
  → Топики: user_{parentUid}
  → Сообщение: "Статус [имя ребёнка] обновлён."

Если изменилась group_id:
  → Топики: user_{parentUid}
  → Сообщение: "[Имя ребёнка] переведён в другую группу."
```

## Логирование

Добавлены логи для отладки:
- `[main]` — инициализация Firebase
- `[AuthWrapper]` — конфигурация подписок при входе
- `[NotificationTopicService]` — управление подписками
- `[ProfileService]` — загрузка групп детей
- `[GroupsService]` — загрузка групп учителя

Примеры логов:
```
[main] Firebase инициализирован
[main] NotificationService инициализирован
[AuthWrapper] Начинаю конфигурацию подписок для user123 (роль: user)
[AuthWrapper] notificationsEnabled: true
[ProfileService] getChildGroupIds: Загруженные кешированные дети: 2
[GroupsService] fetchTeacherGroupIds: Найдено групп: 1, IDs: [group1]
[NotificationTopicService] Желаемые топики: {general, parents, user_user123, group_group1}
[✓] Подписка на general успешна
[✓] Подписка на parents успешна
...
```

## Развёртывание

### 1. Развернуть Cloud Functions
```bash
cd functions
npm install --legacy-peer-deps
firebase deploy --only functions
```

### 2. Обновить firebase.json
```json
{
  "projects": {
    "default": "YOUR_PROJECT_ID"
  }
}
```

### 3. Установить Firebase CLI
```bash
npm install -g firebase-tools
firebase login
firebase init
```

## Отладка

### Проверить логи приложения
В консоли Flutter смотреть логи с префиксами:
- `[main]`
- `[AuthWrapper]`
- `[NotificationTopicService]`

### Проверить функции в Firebase Console
1. Перейти в Functions
2. Смотреть логи в Logs tab
3. Проверить метрики ошибок

### Проверить коллекции
1. Убедиться, что документы создаются с правильными полями
2. Проверить, что `notificationsEnabled: true` в профилях

### Тестировать отправку
Через Firebase Console → Messaging → Create a message
- Выбрать Topic: `general` или `parents`
- Отправить тестовое сообщение

## Возможные проблемы

### Уведомления не приходят
1. Проверить, что `notificationsEnabled: true` в профиле пользователя
2. Проверить логи консоли (поиск `[NotificationTopicService]`)
3. Убедиться, что Cloud Functions развернуты
4. Проверить, что события в Firestore вызывают функции
5. Посмотреть логи functions в Firebase Console

### Топики не подписываются
1. Проверить логи `[NotificationTopicService]` с ошибками подписки
2. Убедиться, что у приложения есть разрешение на notifications
3. Перезагрузить приложение

### Функции не срабатывают
1. Проверить синтаксис в `functions/index.js`
2. Переразвернуть: `firebase deploy --only functions`
3. Смотреть логи в Cloud Functions console

## Примечания

- При отключении уведомлений (toggle) все подписки очищаются
- При включении уведомлений заново загружаются группы и переподписываются
- При выходе (signOut) все подписки очищаются автоматически
- Кешированные топики хранятся в SharedPreferences с ключом `subscribed_notification_topics`
