import UserMenuDefaultReviewableItem from "discourse/components/user-menu/default-reviewable-item";
import I18n from "I18n";

export default class UserMenuReviewableFlaggedPostItem extends UserMenuDefaultReviewableItem {
  get description() {
    const title = this.reviewable.topic_title;
    const postNumber = this.reviewable.post_number;
    if (title && postNumber) {
      return I18n.t("user_menu.reviewable.post_number_with_topic_title", {
        post_number: postNumber,
        title,
      });
    } else {
      return I18n.t("user_menu.reviewable.delete_post");
    }
  }

  get descriptionHtmlSafe() {
    return true;
  }
}
