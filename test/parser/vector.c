// Copyright 2018 Craig Barnes.
// Copyright 2011 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <stddef.h>
#include "vector.h"
#include "test.h"

#define SETUP() \
  UNUSED int one_ = 1, two_ = 2, three_ = 3; \
  GumboVector vector_; \
  gumbo_vector_init(2, &vector_)

#define TEARDOWN() \
  gumbo_vector_destroy(&vector_)

TEST(GumboVectorTest, Init) {
  SETUP();
  EXPECT_EQ(0, vector_.length);
  EXPECT_EQ(2, vector_.capacity);
  TEARDOWN();
}

TEST(GumboVectorTest, InitZeroCapacity) {
  SETUP();
  gumbo_vector_destroy(&vector_);
  gumbo_vector_init(0, &vector_);

  gumbo_vector_add(&one_, &vector_);
  EXPECT_EQ(1, vector_.length);
  EXPECT_EQ(1, *((int*)(vector_.data[0])));
  TEARDOWN();
}

TEST(GumboVectorTest, Add) {
  SETUP();
  gumbo_vector_add(&one_, &vector_);
  EXPECT_EQ(1, vector_.length);
  EXPECT_EQ(1, *(int*)(vector_.data[0]));
  EXPECT_EQ(0, gumbo_vector_index_of(&vector_, &one_));
  EXPECT_EQ(-1, gumbo_vector_index_of(&vector_, &two_));
  TEARDOWN();
}

TEST(GumboVectorTest, AddMultiple) {
  SETUP();
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  EXPECT_EQ(2, vector_.length);
  EXPECT_EQ(2, *((int*)(vector_.data[1])));
  EXPECT_EQ(1, gumbo_vector_index_of(&vector_, &two_));
  TEARDOWN();
}

TEST(GumboVectorTest, Realloc) {
  SETUP();
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_add(&three_, &vector_);
  EXPECT_EQ(3, vector_.length);
  EXPECT_EQ(4, vector_.capacity);
  EXPECT_EQ(3, *((int*)(vector_.data[2])));
  TEARDOWN();
}

TEST(GumboVectorTest, Pop) {
  SETUP();
  gumbo_vector_add(&one_, &vector_);
  int result = *(int*)(gumbo_vector_pop(&vector_));
  EXPECT_EQ(1, result);
  EXPECT_EQ(0, vector_.length);
  TEARDOWN();
}

TEST(GumboVectorTest, PopEmpty) {
  SETUP();
  EXPECT_EQ(NULL, gumbo_vector_pop(&vector_));
  TEARDOWN();
}

TEST(GumboVectorTest, InsertAtFirst) {
  SETUP();
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_insert_at(&three_, 0, &vector_);
  EXPECT_EQ(3, vector_.length);
  int result = *(int*)(vector_.data[0]);
  EXPECT_EQ(3, result);
  TEARDOWN();
}

TEST(GumboVectorTest, InsertAtLast) {
  SETUP();
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_insert_at(&three_, 2, &vector_);
  EXPECT_EQ(3, vector_.length);
  int result = *(int*)(vector_.data[2]);
  EXPECT_EQ(3, result);
  TEARDOWN();
}

TEST(GumboVectorTest, Remove) {
  SETUP();
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_add(&three_, &vector_);
  gumbo_vector_remove(&two_, &vector_);
  EXPECT_EQ(2, vector_.length);
  int three = *(int*)(vector_.data[1]);
  EXPECT_EQ(3, three);
  TEARDOWN();
}

TEST(GumboVectorTest, RemoveAt) {
  SETUP();
  gumbo_vector_add(&one_, &vector_);
  gumbo_vector_add(&two_, &vector_);
  gumbo_vector_add(&three_, &vector_);
  int result = *(int*)(gumbo_vector_remove_at(1, &vector_));
  EXPECT_EQ(2, result);
  EXPECT_EQ(2, vector_.length);
  int three = *(int*)(vector_.data[1]);
  EXPECT_EQ(3, three);
  TEARDOWN();
}
