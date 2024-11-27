const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {initializeApp} = require("firebase-admin/app");
const schedule = require("node-schedule");
const {logger} = require("firebase-functions");

// Initialize Firebase Admin
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

exports.scheduleTaskNotifications = onDocumentWritten(
    "tasks/{taskId}",
    async (event) => {
      logger.info("New Trigger Received");
      const afterData = event.data?.after?.data(); // Data after the change

      // If the task is deleted or doesn't have a timer set, skip notification
      if (!afterData || !afterData.timerSet) {
        logger.info("Task deleted or timer not set. Skipping notification.");
        return;
      }

      const {taskDate, participantsStatus, name, description} = afterData;

      // Parse the taskDate string into a JavaScript Date object
      let taskDateObj;
      if (taskDate && typeof taskDate.toDate === "function") {
        // If it's a Firestore Timestamp
        taskDateObj = taskDate.toDate();
      } else {
        // Assume it's a plain Date string or object
        taskDateObj = new Date(taskDate);
      }

      if (isNaN(taskDateObj.getTime())) {
        logger.info("Invalid task date. Skipping notification.");
        return;
      }

      // Skip notifications if the task date is in the past
      if (taskDateObj < new Date()) {
        logger.info("Task date is in the past. Skipping notification.");
        return;
      }

      // Filter participantsStatus for users with status false
      const uids = Object.entries(participantsStatus)
          .filter(([userId, status]) => !status)
          .map(([userId]) => userId); // Extract the userId

      logger.info(`Task: "${name}" at ${taskDateObj} for ${uids.join(", ")}`);

      // Schedule the notification using node-schedule
      schedule.scheduleJob(taskDateObj, async () => {
        const tokens = [];

        for (const [userId, status] of Object.entries(participantsStatus)) {
          if (!status) {
            try {
              const userDoc = await db.collection("users").doc(userId).get();
              if (userDoc.exists && userDoc.data()?.fcmToken) {
                const fcmToken = userDoc.data().fcmToken;
                const userId = userDoc.id; // Extract the user ID
                logger.info(`User found: ${userId}, FCM: ${fcmToken}`);
                tokens.push(fcmToken);
              }
            } catch (err) {
              logger.info(`Error fetching user ${userId}:`, err);
            }
          }
        }

        if (tokens.length === 0) {
          logger.info("No users to notify.");
          return;
        }

        const payload = {
          notification: {
            title: `Task due: ${name}`,
            body: description || "It's time to GET UP!!",
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1, // Optional: Updates the app's badge count
                alert: {
                  title: `Reminder: ${name}`,
                  body: description || "You have a task coming up.",
                },
              },
            },
            headers: {
              "apns-priority": "10", // Ensure high-priority
            },
          },
        };

        try {
          // Use sendEachForMulticast for better token-level error handling
          const responses = await messaging.sendEachForMulticast({
            tokens, // Array of FCM tokens
            ...payload,
          });

          responses.responses.forEach((response, index) => {
            if (response.success) {
              logger.info(`Successfully sent to token: ${tokens[index]}`);
            } else {
              logger.info(
                  `Failed: ${tokens[index]}, Error: ${response.error}`,
              );
            }
          });

          logger.info(
              `Ok: ${responses.successCount}, No: ${responses.failureCount}`,
          );
        } catch (error) {
          logger.info("Error sending notifications:", error);
        }
      });

      return;
    },
);
