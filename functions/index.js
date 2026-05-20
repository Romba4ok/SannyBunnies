const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const DEFAULT_CHANNEL = 'default_channel';

function groupTopic(groupId) {
  return `group_${groupId}`;
}

function userTopic(uid) {
  return `user_${uid}`;
}

async function sendToTopics(topics, title, body, data = {}) {
  if (!Array.isArray(topics) || topics.length === 0) {
    console.log('Нет топиков для отправки');
    return;
  }

  const validTopics = topics.filter(t => t && typeof t === 'string');
  if (validTopics.length === 0) {
    console.log('Нет валидных топиков');
    return;
  }

  console.log(`Отправка уведомления "${title}" в топики:`, validTopics);

  for (const topic of validTopics) {
    try {
      const message = {
        topic,
        notification: {
          title: title || 'Новое уведомление',
          body: body || 'Появились обновления.',
        },
        data: data,
        android: {
          priority: 'high',
          notification: {
            channelId: DEFAULT_CHANNEL,
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };
      const messageId = await admin.messaging().send(message);
      console.log(`✓ Уведомление отправлено в ${topic}, ID: ${messageId}`);
    } catch (error) {
      console.error(`✗ Ошибка отправки в ${topic}:`, error.message);
    }
  }
}

exports.onNewsCreated = functions.firestore
  .document('news/{newsId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return;

    const title = data.title || 'Новая новость';
    const body = data.shortText || data.description || 'Появилась новая новость для родителей.';

    
    await sendToTopics(['parents'], title, body, {
      newsId: context.params.newsId,
    });
  });

exports.onScheduleChanged = functions.firestore
  .document('schedule/{scheduleId}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return;

    const groupId = after.group_id || after.groupId;
    if (!groupId) return;

    const title = 'Обновлено расписание';
    const body = after.title
      ? `Расписание ${after.title} изменено для вашей группы.`
      : 'Расписание для вашей группы обновлено.';

    await sendToTopics([groupTopic(groupId)], title, body, {
      scheduleId: context.params.scheduleId,
      groupId,
    });
  });

exports.onChildUpdated = functions.firestore
  .document('children/{childId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const childName = after.name || before.name || 'Ребёнок';
    const parentUid = after.parent_uid || before.parent_uid;
    const groupId = after.group_id || before.group_id;

    const requestStatusChanged = before.requestStatus !== after.requestStatus;
    const groupChanged = before.group_id !== after.group_id;
    const statusChanged = before.status !== after.status || before.mood !== after.mood || before.temperature !== after.temperature || before.absent !== after.absent;

    if (requestStatusChanged) {
      const requestStatus = after.requestStatus;
      const statusText = requestStatus === null
        ? 'отменена'
        : requestStatus === true
          ? 'принята'
          : 'создана новая заявка';

      const title = 'Статус заявки ребёнка';
      const body = `${childName}: заявка ${statusText}.`;

      const topics = ['teachers'];
      if (groupId) {
        topics.push(groupTopic(groupId));
      }
      await sendToTopics(topics, title, body, {
        childId: context.params.childId,
        parentUid,
      });
    }

    if (statusChanged && parentUid) {
      const title = 'Обновлен статус ребёнка';
      const body = `Статус ${childName} обновлён.`;
      await sendToTopics([userTopic(parentUid)], title, body, {
        childId: context.params.childId,
      });
    }

    if (groupChanged && parentUid) {
      const title = 'Изменена группа ребёнка';
      const body = `${childName} переведён в другую группу.`;
      await sendToTopics([userTopic(parentUid)], title, body, {
        childId: context.params.childId,
        groupId,
      });
    }
  });
