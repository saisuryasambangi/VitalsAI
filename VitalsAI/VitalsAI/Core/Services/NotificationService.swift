import UserNotifications
import Foundation

@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private static let weeklyID  = "com.vitalsai.weekly-reminder"
    private static let kickoffID = "com.vitalsai.weekly-reminder.kickoff"

    // MARK: - Permission

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Schedule

    /// Schedules a weekly reminder.
    /// The first fire is always the 1st of next month at `hour:00`
    /// so enabling today still lands in the future month.
    /// After that it repeats every `weekday` at `hour:00`.
    ///
    /// - Parameters:
    ///   - weekday: 1 = Sunday … 7 = Saturday. Default 2 = Monday.
    ///   - hour: 24-hour clock. Default 9.
    func scheduleWeeklyReminder(weekday: Int = 2, hour: Int = 9) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.weeklyID, Self.kickoffID])

        let content = UNMutableNotificationContent()
        content.title = "Time for your weekly health check"
        content.body = "See how your steps, sleep, and heart rate look this week."
        content.sound = .default

        // ── Kickoff: 1st of next month ────────────────────────────────
        let cal = Calendar.current
        var kickoff = cal.dateComponents([.year, .month], from: Date())
        kickoff.month = (kickoff.month ?? 1) + 1
        kickoff.day   = 1
        kickoff.hour  = hour
        kickoff.minute = 0

        let kickoffTrigger = UNCalendarNotificationTrigger(dateMatching: kickoff, repeats: false)
        center.add(UNNotificationRequest(
            identifier: Self.kickoffID,
            content: content,
            trigger: kickoffTrigger
        ))

        // ── Repeating weekly thereafter ───────────────────────────────
        var weekly = DateComponents()
        weekly.weekday = weekday
        weekly.hour    = hour
        weekly.minute  = 0

        let weeklyTrigger = UNCalendarNotificationTrigger(dateMatching: weekly, repeats: true)
        center.add(UNNotificationRequest(
            identifier: Self.weeklyID,
            content: content,
            trigger: weeklyTrigger
        ))
    }

    func cancelWeeklyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.weeklyID, Self.kickoffID])
    }

    // MARK: - Status

    func isReminderScheduled() async -> Bool {
        let pending = await center.pendingNotificationRequests()
        let ids = Set(pending.map(\.identifier))
        return ids.contains(Self.weeklyID) || ids.contains(Self.kickoffID)
    }

    /// Returns the soonest upcoming fire date across both requests.
    func nextFireDate() async -> Date? {
        let pending = await center.pendingNotificationRequests()
        let dates = pending
            .filter { [Self.weeklyID, Self.kickoffID].contains($0.identifier) }
            .compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
        return dates.min()
    }
}
