import UserMenuNotificationItem from "discourse/components/user-menu/notification-item";
import { userPath } from "discourse/lib/url";
import I18n from "I18n";

export default class UserMenuInviteeAcceptedNotificationItem extends UserMenuNotificationItem {
  get url() {
    return userPath(this.data.display_username);
  }

  get description() {
    return I18n.t("notifications.invitee_accepted_your_invitation");
  }

  get descriptionHtmlSafe() {
    return false;
  }
}
