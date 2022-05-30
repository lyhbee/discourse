import UserMenuNotificationItem from "discourse/components/user-menu/notification-item";
import I18n from "I18n";

export default class UserMenuBookmarkReminderNotificationItem extends UserMenuNotificationItem {
  get linkTitle() {
    if (this.notificationName && this.data.bookmark_name) {
      return I18n.t(`notifications.titles.${this.notificationName}_with_name`, {
        name: this.data.bookmark_name,
      });
    }
    return super.linkTitle;
  }
}
