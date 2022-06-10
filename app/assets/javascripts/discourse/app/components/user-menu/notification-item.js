import GlimmerComponent from "discourse/components/glimmer";
import { formatUsername, postUrl } from "discourse/lib/utilities";
import { userPath } from "discourse/lib/url";
import { setTransientHeader } from "discourse/lib/ajax";
import { action } from "@ember/object";
import getURL from "discourse-common/lib/get-url";
import cookie from "discourse/lib/cookie";
import I18n from "I18n";

let _decorators = [];
export function registerTopicTitleDecorator(dec) {
  _decorators.push(dec);
}

export function resetTopicTitleDecorators() {
  _decorators = [];
}

export default class UserMenuNotificationItem extends GlimmerComponent {
  get className() {
    // TODO handle mod warning message in pm notification item
    const classes = [];
    if (this.notification.read) {
      classes.push("read");
    }
    if (this.notificationName) {
      classes.push(this.notificationName.replace(/_/g, "-"));
    }
    return classes.join(" ");
  }

  get url() {
    if (this.topicId) {
      return postUrl(
        this.notification.slug,
        this.topicId,
        this.notification.post_number
      );
    }
    if (this.data.group_id) {
      return userPath(`${this.data.username}/messages/${this.data.group_name}`);
    }
  }

  get linkTitle() {
    if (this.notificationName) {
      return I18n.t(`notifications.titles.${this.notificationName}`);
    } else {
      return "";
    }
  }

  get icon() {
    return `notification.${this.notificationName}`;
  }

  get label() {
    return this.username;
  }

  get wrapLabel() {
    return true;
  }

  get labelWrapperClasses() {}

  get username() {
    return formatUsername(this.data.display_username);
  }

  get description() {
    return this._decoratedTopicTitle;
  }

  get descriptionElementClasses() {
    const classes = [];
    if (this.data.group_name && this.notification.fancy_title) {
      classes.push("mention-group", "notify");
    }
    return classes.join(" ");
  }

  get descriptionHtmlSafe() {
    return !!this.notification.fancy_title;
  }

  // the following props are helper props -- they're never referenced directly in the hbs template
  get notification() {
    return this.args.item;
  }

  get topicId() {
    return this.notification.topic_id;
  }

  get data() {
    return this.notification.data;
  }

  get notificationName() {
    return this.site.notificationLookup[this.notification.notification_type];
  }

  get _decoratedTopicTitle() {
    let title = this.notification.fancy_title;
    if (title) {
      _decorators.forEach((dec) => {
        const updated = dec(title, this.notification);
        if (updated) {
          title = updated;
        }
      });
    }
    return title;
  }

  @action
  onClick() {
    if (!this.notification.read) {
      this.notification.set("read", true);
      setTransientHeader("Discourse-Clear-Notifications", this.notification.id);
      cookie("cn", this.notification.id, { path: getURL("/") });
    }
  }
}
