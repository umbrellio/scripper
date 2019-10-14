# frozen_string_literal: true

RSpec.describe Scripper::Sequel do
  include_context "sequel context"

  context "single object stripping" do
    subject(:stripped_user) { described_class.strip(user) }

    context "basic attribute stripping" do
      let(:user) do
        user_model.create(
          email: "billikota@billikota.billikota",
          password: "12345",
          loc_written: 69,
        )
      end

      it "strips the object down to a Struct" do
        expect(stripped_user).to be_a(Struct)

        expect(stripped_user).to have_attributes(
          id: user.id,
          email: "billikota@billikota.billikota",
          password: "12345",
        )
      end

      it "converts numeric values to floats" do
        expect(stripped_user).to have_attributes(loc_written: 69)

        expect(stripped_user.loc_written).to be_an(Float)
      end
    end

    context "jsonb attribute stripping" do
      let(:user) do
        user_model.create(
          preferences: {
            loves_milk: true,
          },
          cars: %w[some_audi],
        )
      end

      it "converts pg json hashes to Ruby hashes" do
        expect(stripped_user).to have_attributes(
          preferences: {
            "loves_milk" => true,
          },
        )

        expect(stripped_user.preferences).to be_a(Hash)
      end

      it "converts pg json arrays to Ruby arrays" do
        expect(stripped_user).to have_attributes(
          cars: %w[some_audi],
        )

        expect(stripped_user.cars).to be_an(Array)
      end

      context "complex json data" do
        let(:user) do
          user_model.create(
            preferences: {
              loves_milk: true,
              notifications: {
                push: true,
                email: false,
                sms: false,
              },
              subscriptions: [{ provider: :mir_obmana, period: :lifetime }],
            },
            cars: [
              { manufacturer: "Chevrolet", model: "Caprice", year: 1993 },
              { manufacturer: "Ford", model: "Galaxy", year: 2012 },
            ],
          )
        end

        it "performs deep conversions" do
          expect(stripped_user).to have_attributes(
            preferences: {
              "loves_milk" => true,
              "notifications" => {
                "push" => true,
                "email" => false,
                "sms" => false,
              },
              "subscriptions" => [{ "provider" => "mir_obmana", "period" => "lifetime" }],
            },
            cars: [
              { "manufacturer" => "Chevrolet", "model" => "Caprice", "year" => 1993 },
              { "manufacturer" => "Ford", "model" => "Galaxy", "year" => 2012 },
            ],
          )

          expect(stripped_user.preferences).to be_a(Hash)

          expect(stripped_user.preferences["notifications"]).to be_a(Hash)
          expect(stripped_user.preferences["subscriptions"]).to be_an(Array)
          expect(stripped_user.preferences["subscriptions"].first).to be_a(Hash)

          expect(stripped_user.cars).to be_an(Array)
          expect(stripped_user.cars.first).to be_a(Hash)
        end
      end
    end

    context "text[]" do
      let(:user) do
        user_model.create(pseudonyms: Sequel.pg_array(%w[cow ковыч корова цой жиэсапокалипсис]))
      end

      it "converts text[] to an array of strings" do
        expect(stripped_user).to have_attributes(
          pseudonyms: %w[cow ковыч корова цой жиэсапокалипсис],
        )

        expect(stripped_user.pseudonyms).to be_a(Array)
        expect(stripped_user.pseudonyms.map(&:class).uniq).to eq([String])
      end
    end
  end

  context "working with associations" do
    let(:user) do
      user_model.create
    end

    let!(:cookies) do
      cookie_model.create(user_id: user.id, value: "nice")
      cookie_model.create(user_id: user.id, value: "job")
    end

    let!(:role) do
      role_model.create(user_id: user.id, title: "volk")
    end

    context "one(many)-to-many" do
      context "load all associated records" do
        subject(:stripped_user) { described_class.strip(user, with_associations: %i[cookies]) }

        it "loads all associated cookies and strips them" do
          expect(stripped_user.cookies).to be_an(Array)
          expect(stripped_user.cookies.count).to eq(2)

          expect(stripped_user.cookies.first).to be_a(Struct)
          expect(stripped_user.cookies.first).to have_attributes(
            user_id: user.id,
            value: "nice",
          )
        end
      end

      context "select only some records" do
        subject(:stripped_user) do
          described_class.strip(user, with_associations: { cookies: -> (ds) { ds.limit(1) } })
        end

        it "applies specified conditions to associations" do
          expect(stripped_user.cookies).to be_an(Array)
          expect(stripped_user.cookies.count).to eq(1)

          expect(stripped_user.cookies.first).to be_an(Struct)
        end
      end
    end

    context "one-to-one" do
      subject(:stripped_user) { described_class.strip(user, with_associations: %i[role]) }

      it "loads the role" do
        expect(stripped_user.role).to be_a(Struct)
        expect(stripped_user.role.title).to eq("volk")
      end
    end
  end

  context "providing extra attributes" do
    subject(:stripped_user) do
      described_class.strip(user, with_attributes: { payment_sum: user[:payment_sum] })
    end

    before do
      user = user_model.create
      DB[:payments].insert(actor_id: user.id, amount: 69)
      DB[:payments].insert(actor_id: user.id, amount: 418)
    end

    let(:user) do
      User
        .left_join(:payments, actor_id: Sequel[:users][:id])
        .select_all(:users)
        .select_append(Sequel.function(:sum, Sequel[:payments][:amount]).as(:payment_sum))
        .group(Sequel[:users][:id])
        .first
    end

    it "adds a method #payment_sum" do
      expect(stripped_user).to have_attributes(payment_sum: 487)
      expect(stripped_user.payment_sum).to be_a(Float)
    end
  end

  context "working with datasets" do
    subject(:stripped_user) { described_class.strip(user) }

    before do
      user = user_model.create(
        email: "cow@cow.cow",
        password: "12345",
        loc_written: 69,
      )

      DB[:payments].insert(actor_id: user.id, amount: 418)
    end

    let(:user) { DB[:users].first }

    it "works just like with models" do
      expect(stripped_user).to be_a(Struct)

      expect(stripped_user).to have_attributes(
        id: user[:id],
        email: "cow@cow.cow",
        password: "12345",
        loc_written: 69,
      )

      expect(stripped_user.loc_written).to be_a(Float)
    end

    context "with extra attributes" do
      subject(:stripped_user) do
        described_class.strip(user)
      end

      let(:user) do
        DB[:users]
          .left_join(:payments, actor_id: Sequel[:users][:id])
          .select_all(:users)
          .select_append(Sequel.function(:sum, Sequel[:payments][:amount]).as(:payment_sum))
          .group(Sequel[:users][:id])
          .first
      end

      it "works just like with models" do
        expect(stripped_user).to have_attributes(
          id: user[:id],
          email: "cow@cow.cow",
          password: "12345",
          loc_written: 69,
          payment_sum: 418,
        )

        expect(stripped_user.payment_sum).to be_a(Float)
      end
    end
  end
end
