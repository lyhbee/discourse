# frozen_string_literal: true

describe Jobs::NotifyReviewable do
  describe '#execute' do
    fab!(:admin) { Fabricate(:admin, moderator: true) }
    fab!(:moderator) { Fabricate(:moderator) }
    fab!(:group_user) { Fabricate(:group_user) }
    fab!(:user) { group_user.user }
    fab!(:group) { group_user.group }

    it "will notify users of new reviewable content" do
      SiteSetting.enable_category_group_moderation = true

      GroupUser.create!(group_id: group.id, user_id: moderator.id)

      # Content for admins only
      r1 = Fabricate(:reviewable, reviewable_by_moderator: false)
      messages = MessageBus.track_publish("/reviewable_counts") do
        described_class.new.execute(reviewable_id: r1.id)
      end
      admin_msg = messages.find { |m| m.user_ids.include?(admin.id) }
      expect(admin_msg.data[:reviewable_count]).to eq(1)
      expect(messages.any? { |m| m.user_ids.include?(moderator.id) }).to eq(false)
      expect(messages.any? { |m| m.user_ids.include?(user.id) }).to eq(false)

      # Content for moderators
      r2 = Fabricate(:reviewable, reviewable_by_moderator: true)
      messages = MessageBus.track_publish("/reviewable_counts") do
        described_class.new.execute(reviewable_id: r2.id)
      end
      admin_msg = messages.find { |m| m.user_ids.include?(admin.id) }
      expect(admin_msg.data[:reviewable_count]).to eq(2)
      mod_msg = messages.find { |m| m.user_ids.include?(moderator.id) }
      expect(mod_msg.data[:reviewable_count]).to eq(1)
      expect(mod_msg.user_ids).to_not include(admin.id)
      expect(messages.any? { |m| m.user_ids.include?(user.id) }).to eq(false)

      # Content for a group
      r3 = Fabricate(:reviewable, reviewable_by_moderator: true, reviewable_by_group: group)
      messages = MessageBus.track_publish("/reviewable_counts") do
        described_class.new.execute(reviewable_id: r3.id)
      end
      admin_msg = messages.find { |m| m.user_ids.include?(admin.id) }
      expect(admin_msg.data[:reviewable_count]).to eq(3)
      mod_messages = messages.select { |m| m.user_ids.include?(moderator.id) }
      expect(mod_messages.size).to eq(1)
      expect(mod_messages[0].data[:reviewable_count]).to eq(2)
      group_msg = messages.find { |m| m.user_ids.include?(user.id) }
      expect(group_msg.data[:reviewable_count]).to eq(1)
    end

    it "won't notify a group when disabled" do
      SiteSetting.enable_category_group_moderation = false

      GroupUser.create!(group_id: group.id, user_id: moderator.id)
      r3 = Fabricate(:reviewable, reviewable_by_moderator: true, reviewable_by_group: group)
      messages = MessageBus.track_publish("/reviewable_counts") do
        described_class.new.execute(reviewable_id: r3.id)
      end
      group_msg = messages.find { |m| m.user_ids.include?(user.id) }
      expect(group_msg).to be_blank
    end

    it "respects visibility" do
      SiteSetting.enable_category_group_moderation = true
      Reviewable.set_priorities(medium: 2.0)
      SiteSetting.reviewable_default_visibility = 'medium'

      GroupUser.create!(group_id: group.id, user_id: moderator.id)

      # Content for admins only
      r1 = Fabricate(:reviewable, reviewable_by_moderator: false)
      messages = MessageBus.track_publish("/reviewable_counts") do
        described_class.new.execute(reviewable_id: r1.id)
      end
      admin_msg = messages.find { |m| m.user_ids.include?(admin.id) }
      expect(admin_msg.data[:reviewable_count]).to eq(0)

      # Content for moderators
      r2 = Fabricate(:reviewable, reviewable_by_moderator: true)
      messages = MessageBus.track_publish("/reviewable_counts") do
        described_class.new.execute(reviewable_id: r2.id)
      end
      admin_msg = messages.find { |m| m.user_ids.include?(admin.id) }
      expect(admin_msg.data[:reviewable_count]).to eq(0)
      mod_msg = messages.find { |m| m.user_ids.include?(moderator.id) }
      expect(mod_msg.data[:reviewable_count]).to eq(0)

      # Content for a group
      r3 = Fabricate(:reviewable, reviewable_by_moderator: true, reviewable_by_group: group)
      messages = MessageBus.track_publish("/reviewable_counts") do
        described_class.new.execute(reviewable_id: r3.id)
      end
      admin_msg = messages.find { |m| m.user_ids.include?(admin.id) }
      expect(admin_msg.data[:reviewable_count]).to eq(0)
      mod_messages = messages.select { |m| m.user_ids.include?(moderator.id) }
      expect(mod_messages.size).to eq(1)
      expect(mod_messages[0].data[:reviewable_count]).to eq(0)
      group_msg = messages.find { |m| m.user_ids.include?(user.id) }
      expect(group_msg.data[:reviewable_count]).to eq(0)
    end

    context "when enable_revamped_user_menu setting is on" do
      fab!(:admin2) { Fabricate(:admin, moderator: true) }
      fab!(:moderator2) { Fabricate(:moderator) }
      fab!(:user2) { Fabricate(:user, groups: [group]) }

      before do
        SiteSetting.enable_revamped_user_menu = true
      end

      it "will notify users of new reviewable content" do
        SiteSetting.enable_category_group_moderation = true

        GroupUser.create!(group_id: group.id, user_id: moderator.id)

        # Content for admins only
        r1 = Fabricate(:reviewable, reviewable_by_moderator: false)
        admin2.update!(last_seen_reviewable_id: r1.id)
        admin_messages = MessageBus.track_publish("/reviewable_counts") do
          described_class.new.execute(reviewable_id: r1.id)
        end
        expect(admin_messages.size).to eq(2)

        admin_data = admin_messages.find { |m| m.user_ids == [admin.id] }.data
        expect(admin_data[:reviewable_count]).to eq(1)
        expect(admin_data[:unseen_reviewable_count]).to eq(1)

        admin2_data = admin_messages.find { |m| m.user_ids == [admin2.id] }.data
        expect(admin2_data[:reviewable_count]).to eq(1)
        expect(admin2_data[:unseen_reviewable_count]).to eq(0)

        # Content for moderators
        r2 = Fabricate(:reviewable, reviewable_by_moderator: true)
        messages = MessageBus.track_publish("/reviewable_counts") do
          described_class.new.execute(reviewable_id: r2.id)
        end
        expect(messages.size).to eq(4)

        admin_messages = messages.select { |m| (m.user_ids - [admin.id, admin2.id]).empty? }
        expect(admin_messages.size).to eq(2)

        admin_data = admin_messages.find { |m| m.user_ids == [admin.id] }.data
        expect(admin_data[:reviewable_count]).to eq(2)
        expect(admin_data[:unseen_reviewable_count]).to eq(2)

        admin2_data = admin_messages.find { |m| m.user_ids == [admin2.id] }.data
        expect(admin2_data[:reviewable_count]).to eq(2)
        expect(admin2_data[:unseen_reviewable_count]).to eq(1)

        mod_messages = messages.select { |m| !admin_messages.include?(m) }
        expect(mod_messages.size).to eq(2)

        mod_data = mod_messages.find { |m| m.user_ids == [moderator.id] }.data
        expect(mod_data[:reviewable_count]).to eq(1)
        expect(mod_data[:unseen_reviewable_count]).to eq(1)

        mod2_data = mod_messages.find { |m| m.user_ids == [moderator2.id] }.data
        expect(mod2_data[:reviewable_count]).to eq(1)
        expect(mod2_data[:unseen_reviewable_count]).to eq(1)

        admin.update!(last_seen_reviewable_id: r2.id)
        moderator2.update!(last_seen_reviewable_id: r2.id)

        # Content for a group
        r3 = Fabricate(:reviewable, reviewable_by_moderator: true, reviewable_by_group: group)
        messages = MessageBus.track_publish("/reviewable_counts") do
          described_class.new.execute(reviewable_id: r3.id)
        end
        expect(messages.size).to eq(6)

        admin_messages = messages.select { |m| (m.user_ids - [admin.id, admin2.id]).empty? }
        expect(admin_messages.size).to eq(2)

        admin_data = admin_messages.find { |m| m.user_ids == [admin.id] }.data
        expect(admin_data[:reviewable_count]).to eq(3)
        expect(admin_data[:unseen_reviewable_count]).to eq(1)

        admin2_data = admin_messages.find { |m| m.user_ids == [admin2.id] }.data
        expect(admin2_data[:reviewable_count]).to eq(3)
        expect(admin2_data[:unseen_reviewable_count]).to eq(2)

        mod_messages = messages.select { |m| (m.user_ids - [moderator.id, moderator2.id]).empty? }
        expect(mod_messages.size).to eq(2)

        mod_data = mod_messages.find { |m| m.user_ids == [moderator.id] }.data
        expect(mod_data[:reviewable_count]).to eq(2)
        expect(mod_data[:unseen_reviewable_count]).to eq(2)

        mod2_data = mod_messages.find { |m| m.user_ids == [moderator2.id] }.data
        expect(mod2_data[:reviewable_count]).to eq(2)
        expect(mod2_data[:unseen_reviewable_count]).to eq(1)

        group_messages = messages.select { |m| !admin_messages.include?(m) && !mod_messages.include?(m) }
        expect(group_messages.size).to eq(2)

        group_user_data = group_messages.find { |m| m.user_ids == [user.id] }.data
        expect(group_user_data[:reviewable_count]).to eq(1)
        expect(group_user_data[:unseen_reviewable_count]).to eq(1)

        group_user2_data = group_messages.find { |m| m.user_ids == [user2.id] }.data
        expect(group_user2_data[:reviewable_count]).to eq(1)
        expect(group_user2_data[:unseen_reviewable_count]).to eq(1)
      end

      it "won't notify a group when disabled" do
        SiteSetting.enable_category_group_moderation = false

        GroupUser.create!(group_id: group.id, user_id: moderator.id)
        r3 = Fabricate(:reviewable, reviewable_by_moderator: true, reviewable_by_group: group)
        messages = MessageBus.track_publish("/reviewable_counts") do
          described_class.new.execute(reviewable_id: r3.id)
        end
        expect(messages.map(&:user_ids).flatten).to contain_exactly(
          admin.id, admin2.id, moderator.id, moderator2.id
        )
      end
    end
  end

  it 'skips sending notifications if user_ids is empty' do
    reviewable = Fabricate(:reviewable, reviewable_by_moderator: true)
    regular_user = Fabricate(:user)

    messages = MessageBus.track_publish("/reviewable_counts") do
      described_class.new.execute(reviewable_id: reviewable.id)
    end

    expect(messages.size).to eq(0)
  end
end
