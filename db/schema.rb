# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151231134624) do

  create_table "agon_programs", force: true do |t|
    t.string   "title",       limit: 250, null: false
    t.string   "personality", limit: 250, null: false
    t.string   "episode_id",  limit: 250, null: false
    t.string   "page_url",    limit: 767, null: false
    t.string   "state",       limit: 100, null: false
    t.integer  "retry_count",             null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "agon_programs", ["episode_id"], name: "episode_id", unique: true, using: :btree
  add_index "agon_programs", ["page_url"], name: "page_url", using: :btree

  create_table "anitama_programs", force: true do |t|
    t.string   "book_id",     limit: 250, null: false
    t.string   "title",       limit: 250, null: false
    t.datetime "update_time",             null: false
    t.string   "state",       limit: 100, null: false
    t.integer  "retry_count",             null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "anitama_programs", ["book_id", "update_time"], name: "book_id", unique: true, using: :btree

  create_table "hibiki_program_v2s", force: true do |t|
    t.string   "access_id",    limit: 100, null: false
    t.integer  "episode_id",               null: false
    t.string   "title",        limit: 250, null: false
    t.string   "episode_name", limit: 250, null: false
    t.string   "cast",         limit: 250, null: false
    t.string   "state",        limit: 100, null: false
    t.integer  "retry_count",              null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "hibiki_program_v2s", ["access_id", "episode_id"], name: "access_id", unique: true, using: :btree

  create_table "hibiki_programs", force: true do |t|
    t.string   "title",       limit: 250, null: false
    t.string   "comment",     limit: 150, null: false
    t.string   "rtmp_url",    limit: 767, null: false
    t.string   "state",       limit: 100, null: false
    t.integer  "retry_count",             null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "hibiki_programs", ["rtmp_url"], name: "rtmp_url", unique: true, using: :btree

  create_table "jobs", force: true do |t|
    t.string   "ch",         limit: 100, null: false
    t.datetime "start",                  null: false
    t.datetime "end",                    null: false
    t.string   "title",      limit: 250, null: false
    t.string   "state",      limit: 100, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "jobs", ["ch", "end", "state"], name: "end_index", using: :btree
  add_index "jobs", ["ch", "start", "state"], name: "start_index", using: :btree

  create_table "key_value", primary_key: "key", force: true do |t|
    t.string   "value",      limit: 250, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "niconico_live_programs", force: true do |t|
    t.string   "title",           limit: 250, null: false
    t.string   "state",           limit: 100, null: false
    t.boolean  "cannot_recovery",             null: false
    t.text     "memo",                        null: false
    t.integer  "retry_count",                 null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "onsen_programs", force: true do |t|
    t.string   "title",       limit: 250, null: false
    t.string   "number",      limit: 100, null: false
    t.datetime "date",                    null: false
    t.string   "file_url",    limit: 767, null: false
    t.string   "personality", limit: 250, null: false
    t.string   "state",       limit: 100, null: false
    t.integer  "retry_count",             null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "onsen_programs", ["file_url"], name: "file_url", unique: true, using: :btree

  create_table "wikipedia_category_items", force: true do |t|
    t.string   "category",   limit: 100, null: false
    t.string   "title",      limit: 100, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "wikipedia_category_items", ["category", "title"], name: "category", unique: true, using: :btree

end
