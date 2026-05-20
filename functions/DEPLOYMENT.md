# Инструкция по развёртыванию Cloud Functions

## Предварительные условия

1. Firebase project должен быть создан и иметь активный Firestore
2. Установлены:
   - Node.js (v18+)
   - Firebase CLI: `npm install -g firebase-tools`
3. У вас есть доступ к проекту Firebase

## Шаг 1: Инициализация Firebase CLI

```bash
# Войти в Firebase
firebase login

# Инициализировать Firebase (если ещё не инициализирован)
firebase init
```

## Шаг 2: Обновить конфигурацию

Отредактировать `.firebaserc` и установить правильный project ID:

```json
{
  "projects": {
    "default": "YOUR_ACTUAL_PROJECT_ID"
  }
}
```

Где `YOUR_ACTUAL_PROJECT_ID` — ID вашего Firebase проекта (например: `sannybunnies-prod` или `sannybunnies-dev`).

## Шаг 3: Установить зависимости

```bash
cd functions
npm install --legacy-peer-deps
```

## Шаг 4: Развернуть functions

```bash
firebase deploy --only functions
```

Ожидаемый вывод:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/your-project-id/...
Functions Dashboard: https://console.firebase.google.com/project/your-project-id/functions/...
```

## Шаг 5: Проверить развёртывание

1. Открыть Firebase Console
2. Перейти в Functions
3. Должны быть видны три функции:
   - `onNewsCreated`
   - `onScheduleChanged`
   - `onChildUpdated`

## Тестирование

### Способ 1: Через Firebase Console

1. Перейти в Cloud Firestore
2. Создать новый документ в `news` коллекции:
   ```json
   {
     "title": "Test News",
     "description": "This is a test notification"
   }
   ```
3. После создания должны увидеть логи функции в Functions Dashboard

### Способ 2: Через приложение

1. Войти в приложение
2. Отправить событие (например, создать новость если доступно)
3. В консоли Flutter должны появиться логи подписок
4. На устройстве должно прийти локальное уведомление

## Мониторинг

### Смотреть логи функций

```bash
# Логи последней развёртки
firebase functions:log

# Live-логи
firebase functions:log --follow
```

### В Firebase Console

1. Cloud Functions → Logs
2. Фильтр по функции и времени
3. Смотреть успешные/ошибочные выполнения

## Обновление функций

Если изменили код в `functions/index.js`:

```bash
firebase deploy --only functions
```

## Откат

Если функции вызывают проблемы:

```bash
# Удалить функции
firebase functions:delete onNewsCreated
firebase functions:delete onScheduleChanged
firebase functions:delete onChildUpdated
```

Или переразвернуть полностью после откатов в коде.

## Удаление функций

```bash
# Удалить все functions
firebase functions:delete

# Удалить конкретную функцию
firebase functions:delete onNewsCreated
```

## Переменные окружения (если нужны)

Если в будущем потребуются environment variables:

```bash
firebase functions:config:set app.key="value"
firebase functions:config:get > .runtimeconfig.json
firebase deploy --only functions
```

## Troubleshooting

### Ошибка: "Error: Port 5000 is already in use"
```bash
# Удалить процесс
lsof -ti:5000 | xargs kill -9
```

### Ошибка: "Cannot find module 'firebase-admin'"
```bash
cd functions
npm install
npm install --legacy-peer-deps
```

### Ошибка: "PERMISSION_DENIED: Missing or insufficient permissions"
Убедиться, что в Firebase Console → Firestore Security Rules включена возможность для Functions писать в коллекции.

Правила должны содержать что-то вроде:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Успешное развёртывание

Если всё прошло успешно, вы должны увидеть:
- ✔ functions: Finished running predeploy script.
- ✔ functions[onNewsCreated]: Successful update operation.
- ✔ functions[onScheduleChanged]: Successful update operation.
- ✔ functions[onChildUpdated]: Successful update operation.
