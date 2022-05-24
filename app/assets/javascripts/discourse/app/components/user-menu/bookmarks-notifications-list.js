import UserMenuNotificationsList from "discourse/components/user-menu/notifications-list";

export default class UserMenuBookmarksNotificationsList extends UserMenuNotificationsList {
  get filterByTypes() {
    return "bookmark_reminder";
  }
}
