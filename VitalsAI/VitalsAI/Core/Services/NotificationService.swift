import UserNotifications
import Foundation

@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    static let weeklyReminderID = "com.vitalsai.weekly-reminder"

    // MARK: - Permission

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Schedule

    /// Schedules a repeating weekly notification.
    /// - Parameters:
    ///   - weekday: 1 = Sunday … 7 = Saturday (Calendar convention). Default 2 = Monday.
    ///   - hour: 24-hour clock hour. Default 9.
    func scheduleWeeklyReminder(weekday: Int = 2, hour: Int = 9) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.weeklyReminderID])

        let content = UNMutableNotificationContent()
        content.title = "Time for your weekly health check"
        content.body = "See how your steps, sleep, and heart rate look this week."
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.weeklyReminderID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelWeeklyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.weeklyReminderID])
    }

    // MARK: - Status

    func isReminderScheduled() async -> Bool {
        let pending = await center.pendingNotificationRequests()
        return pending.contains { $0.identifier == Self.weeklyReminderID }
    }

    /// Returns the next fire date for the weekly reminder, if scheduled.
    func nextFireDate() async -> Date? {
        let pending = await center.pendingNotificationRequests()
        guard
            let request = pending.first(where: { $0.identifier == Self.weeklyReminderID }),
            let trigger = request.trigger as? UNCalendarNotificationTrigger
        else { return nil }
        return trigger.nextTriggerDate()
    }
}
