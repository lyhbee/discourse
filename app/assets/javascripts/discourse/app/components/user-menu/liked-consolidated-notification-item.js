import UserMenuNotificationItem from "discourse/components/user-menu/notification-item";
import { userPath } from "discourse/lib/url";
import I18n from "I18n";

export default class UserMenuLikedConsolidatedNotificationItem extends UserMenuNotificationItem {
  get url() {
    return userPath(
      `${
        this.args.item.username || this.currentUser.username
      }/notifications/likes-received?acting_username=${this.data.username}`
    );
  }

  get description() {
    return I18n.t("notifications.liked_consolidated_description", {
      count: this.data.count,
    });
  }

  get descriptionHtmlSafe() {
    return false;
  }
}
