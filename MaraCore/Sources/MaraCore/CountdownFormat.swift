import Foundation

/// 남은 시간의 카운트다운 표기와 다음 갱신 시점. 주방 타이머 의미론(올림):
/// 라벨은 "남은 시간이 이 값 이하가 되는 순간" 바뀐다 — 5h 세션은 4h55m00s가 될 때까지 "5h".
/// 5분 초과는 5분 단위, 마지막 5분은 1분 단위로 촘촘해진다.
public enum CountdownFormat {
    static let coarse: TimeInterval = 5 * 60   // 5분 (5분 초과 구간)
    static let fine: TimeInterval = 60          // 1분 (마지막 5분 구간)

    /// 남은 시간을 올림 granularity로 라벨링. 표기는 DurationFormat.compact 재사용.
    public static func label(remaining: TimeInterval) -> String {
        guard remaining.isFinite, remaining > 0 else { return DurationFormat.compact(0) }
        let g = remaining > coarse ? coarse : fine
        return DurationFormat.compact((remaining / g).rounded(.up) * g)
    }

    /// 라벨이 다음에 바뀔 때까지의 시간(타이머 간격). 경계 정렬 — 정확한 순간에 라벨이 바뀐다.
    public static func nextTick(remaining: TimeInterval) -> TimeInterval {
        guard remaining.isFinite, remaining > 0 else { return fine }
        let g = remaining > coarse ? coarse : fine
        let next = ((remaining / g).rounded(.up) - 1) * g   // 바로 아래 경계
        return max(remaining - next, 0.1)                    // 경계 정확 일치 시 0.1초 간격 방지
    }
}
