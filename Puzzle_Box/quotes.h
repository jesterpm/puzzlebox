typedef struct {
    char* line1;
    char* line2;
} line_pair_t;

typedef struct {
    int pairs;
    line_pair_t * lines;
} message_t;

static const int msgcount = 12;
static const message_t messages[] = {
    { 1, (line_pair_t []){ {"Daniel!?", "Is it u?"} } },
    { 4, (line_pair_t []){ {"Finally!", ""        }, 
                           {"You",      "Found me"},
                           {"Let's go", "on an"   },
                           {"Adven-",   "ture"    } } },
    { 3, (line_pair_t []){ {"We're",    "almost"  }, 
                           {"Hey!",     "What's"  },
                           {"Over",     "There"   } } },
    { 3, (line_pair_t []){ {"That was", "fun!"    },
                           {"But now",  "Im tired"},
                           {"Back to",  "Camp?"   } } },
    { 3, (line_pair_t []){ {"Ah,",      "Campfire"},
                           {"Oh, hey,", "I got"   },
                           {"You a",    "gift"    } } }
};
