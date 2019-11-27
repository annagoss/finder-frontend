# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_11_27_142411) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "judgement_sets", force: :cascade do |t|
    t.string "query"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "organisation"
  end

  create_table "scores", force: :cascade do |t|
    t.string "link"
    t.string "judgement"
    t.integer "link_position"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "judgement_set_id", null: false
    t.index ["judgement_set_id"], name: "index_scores_on_judgement_set_id"
  end

  add_foreign_key "scores", "judgement_sets"
end
