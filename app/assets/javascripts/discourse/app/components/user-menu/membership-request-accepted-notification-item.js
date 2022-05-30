import UserMenuNotificationItem from "discourse/components/user-menu/notification-item";
import { groupPath } from "discourse/lib/url";
import I18n from "I18n";

export default class UserMenuMembershipRequestAcceptedNotificationItem extends UserMenuNotificationItem {
  get url() {
    return groupPath(this.data.group_name);
  }

  get label() {
    return I18n.t("notifications.membership_request_accepted", {
      group_name: this.data.group_name,
    });
  }

  get wrapLabel() {
    return false;
  }

  get description() {
    return null;
  }
}
