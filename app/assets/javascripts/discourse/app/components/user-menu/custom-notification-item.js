import UserMenuNotificationItem from "discourse/components/user-menu/notification-item";
import I18n from "I18n";

export default class UserMenuCustomNotificationItem extends UserMenuNotificationItem {
  get linkTitle() {
    if (this.data.title) {
      return I18n.t(this.data.title);
    }
    return super.linkTitle;
  }

  get icon() {
    return `notification.${this.data.message}`;
  }
}
