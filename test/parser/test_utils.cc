// Copyright 2013 Google Inc. All Rights Reserved.
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
//
// Author: jdtang@google.com (Jonathan Tang)

#include "test_utils.h"
#include "error.h"
#include "util.h"

GumboTest::GumboTest()
    : options_(kGumboDefaultOptions), errors_are_expected_(false), text_("") {
  options_.max_errors = 100;
  parser_._options = &options_;
  parser_._output = static_cast<GumboOutput*>(gumbo_alloc(sizeof(GumboOutput)));
  gumbo_init_errors(&parser_);
}

GumboTest::~GumboTest() {
  if (!errors_are_expected_) {
    // TODO(jdtang): A googlemock matcher may be a more appropriate solution for
    // this; we only want to pretty-print errors that are not an expected
    // output of the test.
    for (unsigned int i = 0; i < parser_._output->errors.length && i < 1; ++i) {
      gumbo_print_caret_diagnostic (
        static_cast<GumboError*>(parser_._output->errors.data[i]),
        text_
      );
    }
  }
  gumbo_destroy_errors(&parser_);
  gumbo_free(parser_._output);
}
