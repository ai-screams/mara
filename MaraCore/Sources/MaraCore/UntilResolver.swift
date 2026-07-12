import Foundation

/// "특정 시각까지(until)" 해석 — 알람의 표준 의미: 오늘의 그 시:분, 이미 지났으면 내일.
/// App의 다이얼로그가 시각 선택 UI와 `.until(Date)` 배선을 맡고, "언제로 해석하는가"라는
/// 결정만 여기(Core, `now`·`calendar` 주입으로 테스트 가능)에 둔다.
public enum UntilResolver {
    /// `timeOfDay`의 시:분을 `now` 기준 다음 발생 시각으로 해석한다.
    /// - `nextDate`가 이미 미래를 반환하므로 보통 그 값이 그대로 쓰이고,
    ///   fallback(`timeOfDay`)이 과거인 예외에서만 달력 +1일로 롤오버한다(24*3600 고정 대신 → DST-safe).
    public static func resolve(timeOfDay: Date,
                               now: Date,
                               calendar: Calendar = .current) -> Date {
        let hm = calendar.dateComponents([.hour, .minute], from: timeOfDay)
        var target = calendar.nextDate(after: now, matching: hm, matchingPolicy: .nextTime) ?? timeOfDay
        if target <= now {
            target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
        }
        return target
    }
}
