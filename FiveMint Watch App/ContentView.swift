import SwiftUI
import EventKit
import UserNotifications

struct ContentView: View {
    @ObservedObject var  viewModel = ReminderViewModel()
    @State private var  selectedCardId: String = ""
    @State private var  selectedCardIndex: Int = notSelected

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let  widthScale = 0.9
                let  heightScale = 0.35
                List {
                    ForEach(Array(self.viewModel.reminders.enumerated()), id: \.element.calendarItemIdentifier) { index, reminder in
                        let  card = self.getCard(index, reminder)

                        CardView(card: card,
                            width: geometry.size.width * widthScale,
                            height: geometry.size.height * heightScale,
                            isSelected: self.selectedCardId == card.calendarItemIdentifier)
                                .modifyCardView(self, card)
                    }

                    let  minimumCount = self.defaultTitle.count
                    if viewModel.reminders.count < minimumCount {
                        ForEach(viewModel.reminders.count..<minimumCount, id: \.self) { index in
                            let  defaultCard = self.getCard(index, nil)

                            CardView(card: defaultCard,
                                width: geometry.size.width * widthScale,
                                height: geometry.size.height * heightScale,
                                isSelected: self.selectedCardId == defaultCard.calendarItemIdentifier)
                                    .modifyCardView(self, defaultCard)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadReminders()
            }
            .navigationTitle(self.title)
            .onReceive(timer) { _ in self.onTimer()}
        }
    }

    @State private var  defaultTitle = ["〜をきれいにする", "ゆっくりする、ねる"]
    @State private var  defaultDescription = ["❗️（しなくては）", "😆（したい）"]
        // This also debug print aera.

    func  getCard(_ index: Int, _ reminderOrNil: EKReminder?) -> Card {
        if let reminder = reminderOrNil {  // not nil

            return  Card(
                index: index,
                calendarItemIdentifier: reminder.calendarItemIdentifier,
                title: reminder.title,
                isDefaultTitle: false,
                description: defaultDescription.element(index, default_: ""))
        } else {  // nil
            var  title = ""
            let  isDefaultTitle = index < self.defaultTitle.count
            if isDefaultTitle {
                title = self.defaultTitle[index]
            }

            return  Card(
                index: index,
                calendarItemIdentifier: String(index),
                title: title,
                isDefaultTitle: isDefaultTitle,
                description: defaultDescription.element(index, default_: ""))
        }
    }

    func  modifyCardView(_ cardView: ModifyCardViewObject.Content, _ card: Card) -> some View {
        return  cardView
            .padding(.all, 1)
            .onTapGesture {self.onTapCard(card)}
            .scaleEffect(self.selectedCardId == card.calendarItemIdentifier ? 1.1 : 1.0)
            .animation(.linear(duration: 0.08), value: self.selectedCardId)
    }

    @State private var  lastNotificationID = ""
    @State private var  notificationDateTime = Date()
    @State private var  countDownDisplayLastDateTime = /*self.*/ getNextAODDateTimeFromNow()

    func  scheduleNotification(_ startOrContinue: Schedule) {
        let  nowAtStart = Date()
        var  passedSeconds: Int
        let  cardSliceSeconds: Int = self.resetCount
        let  intervalSeconds: Int = self.startingInterval
        if startOrContinue == Schedule.start {
            self.notificationDateTime = Calendar.current.date(byAdding: .second, value: cardSliceSeconds, to: nowAtStart)!
            passedSeconds = 0
        } else {
            passedSeconds = (self.resetCount - Int(self.notificationDateTime.timeIntervalSinceNow)) % self.resetCount
            self.lastNotificationID = ""
        }
        let  decimal: TimeInterval = -nowAtStart.timeIntervalSinceNow  // decimal is plus value
        let  notifications = UNUserNotificationCenter.current()
        notifications.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted  &&  self.lastNotificationID == "" {
                notifications.removeAllPendingNotificationRequests()
                notifications.removeAllDeliveredNotifications()
                let  maxNotificationRequestCount = 62  // iOS 12 = 64
                let  catdNotificationCount = 6  // knock x2, Ready(1)(2) and start(3)(4)
                let  reminderLoopCount = maxNotificationRequestCount / catdNotificationCount
                let  firstNextIndex = self.selectedCardIndex
                var  isFirstCard = true

                for reminderLoopIndex in 0..<reminderLoopCount {
                    let  reminderTitle: String
                    if self.selectedCardIndex < self.viewModel.reminders.count {
                        let  reminder = self.viewModel.reminders[self.selectedCardIndex]  // 手動カード切り替えの場合
                        // let  reminder = self.viewModel.reminders[reminderIndex]  // 自動カード切り替えの場合
                        reminderTitle = reminder.title!
                    } else {
                        reminderTitle = self.defaultTitle[self.selectedCardIndex]
                    }
                    if isFirstCard == false {
                        let  nextTime = TimeInterval(-passedSeconds + cardSliceSeconds * reminderLoopIndex)
print("@@@1 \(nextTime), \(passedSeconds), \(cardSliceSeconds), \(reminderLoopIndex)")
                        if nextTime > 0 {

                            if ( nextTime - 2 > 0 ) {
                                self.scheduleUserNotification(
                                    title: "\(reminderTitle)",
                                    subtitle: "knock",
                                    body: "knock",
                                    timeInterval: nextTime - 3,
                                    nowAtStart: nowAtStart,
                                    decimal: decimal)
                            }

                            self.scheduleUserNotification(
                                title: "🔶\(reminderTitle)",
                                subtitle: "5mint(1)",
                                body: "次のタスク",
                                timeInterval: nextTime,
                                nowAtStart: nowAtStart,
                                decimal: decimal)

                            self.scheduleUserNotification(
                                title: "🔶\(reminderTitle)",
                                subtitle: "5mint(2)",
                                body: "次のタスク",
                                timeInterval: nextTime + 0.62,
                                nowAtStart: nowAtStart,
                                decimal: decimal)
                        }
                    }
                    let  nextTime = TimeInterval(-passedSeconds + cardSliceSeconds * reminderLoopIndex + intervalSeconds)
print("@@@2 \(nextTime), \(passedSeconds), \(cardSliceSeconds), \(reminderLoopIndex)")
                    if nextTime > 0 {
                        let  isLast = (reminderLoopIndex == reminderLoopCount - 1  &&
                            reminderLoopIndex == reminderLoopCount - 1)

                        if ( nextTime - 2 > 0 ) {
                            self.scheduleUserNotification(
                                title: "\(reminderTitle)",
                                subtitle: "knock",
                                body: "knock",
                                timeInterval: nextTime - 3,
                                nowAtStart: nowAtStart,
                                decimal: decimal)
                        }

                        self.scheduleUserNotification(
                            title: "🟢\(reminderTitle)",
                            subtitle: "5mint(3)",
                            body: "始めましょう！",
                            timeInterval: nextTime,
                            nowAtStart: nowAtStart,
                            decimal: decimal)

                        self.scheduleUserNotification(
                            title: "🟢\(reminderTitle)",
                            subtitle: "5mint(4)",  // "5mint(9)" にすると、なぜか下記（最後）の "5mint(9)" が鳴らない
                            body: "始めましょう！",
                            timeInterval: nextTime + 0.66,
                            nowAtStart: nowAtStart,
                            decimal: decimal)
                            // 音だけにすると、時計表示のときに通知されません
                            // 2回登録している理由は、時計表示の時に 2回鳴らすことで他の通知と区別できるようにするためです。
                        if isLast {  // 最後は 3回鳴らす
                            self.scheduleUserNotification(
                                title: "🟢終了",
                                subtitle: "5mint(9)",
                                body: "タイマー終了",
                                timeInterval: nextTime + 0.66 * 2,
                                nowAtStart: nowAtStart,
                                decimal: decimal)
                        }
                    }
                    isFirstCard = false
                }
            } else if let error = error {
                print("ERROR in scheduleNotification: \(error.localizedDescription)")
            }
        }
    }

    func  scheduleUserNotification(title: String, subtitle: String, body: String,
            timeInterval: TimeInterval, nowAtStart: Date, decimal: TimeInterval) {
        self.lastNotificationID = UUID().uuidString

        let  content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body  // NSString.localizedUserNotificationString(forKey: "Title", arguments: nil)
        content.sound = UNNotificationSound.default
        // content.categoryIdentifier = directOpenCategory

        let  trigger = UNTimeIntervalNotificationTrigger(timeInterval:
            timeInterval + nowAtStart.timeIntervalSinceNow - decimal, repeats: false)
        let  requestPrepare = UNNotificationRequest(identifier: lastNotificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(requestPrepare)
        // 時刻指定する場合、0.5秒を指定できません UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        // Category: UNUserNotificationCenter.current().setNotificationCategories([category])

        // このアプリがアクティブのときは completionHandler in ExtensionDelegate による通知になります
    }

    func  unscheduleNotification() {
        self.lastNotificationID = ""
        let  notifications = UNUserNotificationCenter.current()
        notifications.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {

                notifications.removeAllPendingNotificationRequests()
                notifications.removeAllDeliveredNotifications()
            } else if let error = error {
                print("ERROR in unscheduleNotification: \(error.localizedDescription)")
            }
        }
        self.remainingSeconds = self.resetCount
    }

    @State private var  title: String = "5:00"
    @State private var  remainingSeconds: Int = 300
    let  resetCount: Int = 300
    let  startingInterval: Int = 60
    // let  resetCount: Int = 26  // 時計画面のときは 10秒で通知が消え、次の通知を表示します。10秒以内ならタイトルが表示されず 2件 3件になります。
    // let  startingInterval: Int = 13   // アプリ画面のときは 5秒で通知が消えます。消える前でも次の通知でタイトルが表示されます
    // let  resetCount: Int = 8  // Very fast test
    // let  startingInterval: Int = 6   // Very fast test
    let  timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func  onTimer() {
        if self.selectedCardId != "" {
            if self.remainingSeconds <= 0 {
                self.remainingSeconds += self.resetCount
                // timer.upstream.connect().cancel()
            }
            self.remainingSeconds -= 1
            self.title = self.getTitle()
        }
    }

    func  getTitle() -> String {
        let now = Date()
        if now < self.countDownDisplayLastDateTime {

            return  "\(self.remainingSeconds / 60):" + "0\(self.remainingSeconds % 60)".suffix(2)
        } else {
            let  formatter = DateFormatter()
            formatter.timeStyle = .short // Hour and minute
            formatter.dateStyle = .none
            formatter.locale = Locale.current

            return  "⏰" + formatter.string(from: self.notificationDateTime)
        }
    }

    func  doResetCount() {
        self.remainingSeconds = self.resetCount
        self.countDownDisplayLastDateTime = ContentView.getNextAODDateTimeFromNow()
    }

    func  onTapCard(_ card: Card) {
        let  now = Date()
        let  newTimer = (self.selectedCardId == ""  ||  self.remainingSeconds == 0  ||  self.remainingSeconds == self.resetCount)
        let  currentCradID = self.selectedCardId
        let  nextCardID = card.calendarItemIdentifier
        self.selectedCardId = (nextCardID != currentCradID  ||  now > self.countDownDisplayLastDateTime
            ) ? nextCardID : ""

        if self.selectedCardId != "" {
            if nextCardID != currentCradID {
                WKInterfaceDevice.current().play(.start)
            } else {
                WKInterfaceDevice.current().play(.click)
            }

            self.selectedCardIndex = card.index
            if newTimer {

                self.scheduleNotification(Schedule.start)
                self.doResetCount()
            } else {
                self.scheduleNotification(Schedule.continue_)
            }
            self.onResume()
        } else {  // Not selected
            WKInterfaceDevice.current().play(.failure)
            self.selectedCardIndex = notSelected
            self.unscheduleNotification()
            self.doResetCount()
        }
        self.title = self.getTitle()
    }

    func  onResume() {
        let  now = Date()
        let  newRemainingSeconds = Int(self.notificationDateTime.timeIntervalSinceNow)

        if now > self.countDownDisplayLastDateTime {
            let  plusSeconds = (-newRemainingSeconds / self.resetCount) * self.resetCount
            self.notificationDateTime = Calendar.current.date(byAdding: .second, value: plusSeconds, to: self.notificationDateTime)!
            if self.notificationDateTime < now {
                self.notificationDateTime = Calendar.current.date(byAdding: .second, value: self.resetCount, to: self.notificationDateTime)!
            }
            self.remainingSeconds = Int(self.notificationDateTime.timeIntervalSinceNow)
        }

        self.countDownDisplayLastDateTime = ContentView.getNextAODDateTimeFromNow()
        self.scheduleNotification(Schedule.continue_)
    }

    static func  getNextAODDateTimeFromNow() -> Date {  // AOD = Always-On Display
        let  now = Date()
    
        return  Calendar.current.date(byAdding: .second, value: 4, to: now)!
    }
}

let  notSelected = -1

enum  Schedule {
    case  start
    case  continue_
}

extension View {
    func modifyCardView(_ self_: ContentView, _ card: Card) -> some View {
        self.modifier(ModifyCardViewObject(self_: self_, card: card))
    }
}

struct ModifyCardViewObject: ViewModifier {
    var self_: ContentView;  var card: Card
    func body(content view: Content) -> some View {
        return  self_.modifyCardView(view, card)
    }
}

extension  Array {
    func  element(_ index: Int, default_: Element) -> Element {
        guard index >= 0 && index < count else {
            return  default_
        }
        return  self[index]
    }
}

#Preview {
    ContentView()
}
