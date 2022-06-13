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

  get description() {
    return super.description || this.data.title;
  }

  get descriptionHtmlSafe() {
    // description can be this.data.title in which case we don't want it to be
    // HTML safe
    if (super.description) {
      return super.descriptionHtmlSafe;
    } else {
      return false;
    }
  }
}
