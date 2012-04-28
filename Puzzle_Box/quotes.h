typedef struct {
    char* line1;
    char* line2;
} line_pair_t;

typedef struct {
    int pairs;
    line_pair_t * lines;
} message_t;

const int msgcount = 12;
const message_t messages[] = {
    { 1, (line_pair_t []){ {"That is" , "my eye!" } } },
    { 1, (line_pair_t []){ {"Ouch!"   , ""        } } },
    { 1, (line_pair_t []){ {"Hey!"    , ""        } } },
    { 2, (line_pair_t []){ {"Stop!"   , ""        }, 
                           {"Poking  ", "Me!"     } } },
    { 2, (line_pair_t []){ {"Great...", "now I"   }, 
                           {"can only", "see 2D"  } } },
    { 3, (line_pair_t []){ {"Grrrr!"  , ""        },
                           {"That."   , "Is."     },
                           {"My."     , "Eye!"    } } },
    { 1, (line_pair_t []){ {"Ouch!"   , "You Suck"} } },
    { 1, (line_pair_t []){ {"I hate"  , "you..."  } } },
    { 1, (line_pair_t []){ {"Abuse!"  , "Abuse!"  } } },
    { 1, (line_pair_t []){ {"Eye   !!", "Murderer"} } },
    { 2, (line_pair_t []){ {"Its dark", "over"    },
                           {"there"   , " >>"     } } },
    { 1, (line_pair_t []){ {"OH! Ouch", "Pain!"   } } } 
};
