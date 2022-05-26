import UserMenuItemsList from "discourse/components/user-menu/items-list";
import I18n from "I18n";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import showModal from "discourse/lib/show-modal";

export default class UserMenuNotificationsList extends UserMenuItemsList {
  get filterByTypes() {
    return null;
  }

  get showAll() {
    return true;
  }

  get showAllHref() {
    return `${this.currentUser.path}/notifications`;
  }

  get showAllTitle() {
    return I18n.t("user_menu.view_all_notifications");
  }

  get showDismiss() {
    return this.items.some((item) => !item.read);
  }

  get dismissTitle() {
    return I18n.t("user.dismiss_notifications_tooltip");
  }

  get itemsCacheKey() {
    let key = "recent-notifications";
    const types = this.filterByTypes?.toString();
    if (types) {
      key += `-type-${types}`;
    }
    return key;
  }

  get emptyStateComponent() {
    if (this.constructor === UserMenuNotificationsList) {
      return "user-menu/notifications-list-empty-state";
    }
  }

  fetchItems() {
    const params = {
      limit: 30,
      recent: true,
      bump_last_seen_reviewable: true,
      silent: this.currentUser.enforcedSecondFactor,
    };

    const types = this.filterByTypes?.toString();
    if (types) {
      params.filter_by_types = types;
    }
    return this.store
      .findStale("notification", params)
      .refresh()
      .then((c) => {
        return c.content;
      });
  }

  dismissWarningModal() {
    if (this.currentUser.unread_high_priority_notifications > 0) {
      const modalController = showModal("dismiss-notification-confirmation");
      modalController.set(
        "confirmationMessage",
        I18n.t("notifications.dismiss_confirmation.body.default", {
          count: this.currentUser.unread_high_priority_notifications,
        })
      );
      return modalController;
    }
  }

  @action
  dismissButtonClick() {
    const opts = { type: "PUT" };
    const dismissTypes = this.filterByTypes?.toString();
    if (dismissTypes) {
      opts.data = { dismiss_types: dismissTypes };
    }
    const modalController = this.dismissWarningModal();
    const modalCallback = () => {
      ajax("/notifications/mark-read", opts).then(() => {
        this.refreshList();
        postRNWebviewMessage("markRead", "1");
      });
    };
    if (modalController) {
      modalController.set("dismissNotifications", modalCallback);
    } else {
      modalCallback();
    }
  }
}
