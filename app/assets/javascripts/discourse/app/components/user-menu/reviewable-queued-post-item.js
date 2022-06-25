import UserMenuDefaultReviewableItem from "discourse/components/user-menu/default-reviewable-item";
import I18n from "I18n";

export default class UserMenuReviewableQueuedPostItem extends UserMenuDefaultReviewableItem {
  get actor() {
    return I18n.t("user_menu.reviewable.queue");
  }

  get description() {
    const title = this.reviewable.topic_title;
    if (this.reviewable.is_new_topic) {
      return title;
    } else {
      return I18n.t("user_menu.reviewable.new_post_in_topic", { title });
    }
  }

  get descriptionHtmlSafe() {
    return !this.reviewable.is_new_topic;
  }

  get icon() {
    return "layer-group";
  }
}
