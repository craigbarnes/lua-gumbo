#ifndef GUMBO_PARSER_H_
#define GUMBO_PARSER_H_

// Contains the definition of the top-level GumboParser structure that's
// threaded through basically every internal function in the library.

struct GumboParserState;
struct GumboOutput;
struct GumboOptions;
struct GumboTokenizerState;

// An overarching struct that's threaded through (nearly) all functions in the
// library, OOP-style. This gives each function access to the options and
// output, along with any internal state needed for the parse.
typedef struct GumboParser {
  // Settings for this parse run.
  const struct GumboOptions* _options;

  // Output for the parse.
  struct GumboOutput* _output;

  // The internal tokenizer state, defined as a pointer to avoid a cyclic
  // dependency on html5tokenizer.h. The main parse routine is responsible for
  // initializing this on parse start, and destroying it on parse end.
  // End-users will never see a non-garbage value in this pointer.
  struct GumboTokenizerState* _tokenizer_state;

  // The internal parser state. Initialized on parse start and destroyed on
  // parse end; end-users will never see a non-garbage value in this pointer.
  struct GumboParserState* _parser_state;
} GumboParser;

#endif  // GUMBO_PARSER_H_
