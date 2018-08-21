// Copyright 2018 Craig Barnes.
// SPDX-License-Identifier: Apache-2.0

#include "attribute.h"
#include "test.h"
#include "vector.h"

TEST(GumboAttributeTest, GetAttribute) {
  GumboVector vector_;
  GumboAttribute attr1;
  GumboAttribute attr2;
  attr1.name = "";
  attr2.name = "foo";

  gumbo_vector_init(2, &vector_);

  gumbo_vector_add(&attr1, &vector_);
  gumbo_vector_add(&attr2, &vector_);
  EXPECT_EQ(&attr2, gumbo_get_attribute(&vector_, "foo"));
  EXPECT_EQ(NULL, gumbo_get_attribute(&vector_, "bar"));

  gumbo_vector_destroy(&vector_);
}
