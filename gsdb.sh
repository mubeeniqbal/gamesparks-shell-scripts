# API documentation: https://docs.gamesparks.com/api-documentation/nosql-rest-api.html

#!/bin/sh

USERNAME=""
PASSWORD=""
API_KEY=""
STAGE=""

CURL_POST_CMD="curl -v --user ${USERNAME}:${PASSWORD} -X POST"

COLLECTION=""
END_POINT="https://portal.gamesparks.net/rest/games/${API_KEY}/mongo/${STAGE}/${COLLECTION}"

FIND_DATA_URL="${END_POINT}/find"
INSERT_DATA_URL="${END_POINT}/insert"
UPDATE_DATA_URL="${END_POINT}/update"
REMOVE_ALL_DATA_URL="-F query={} ${END_POINT}/remove"
AGGREGATE_DATA_URL="${END_POINT}/aggregate"
CREATE_COLLECTION_URL="${END_POINT}/create"
DROP_COLLECTION_URL="${END_POINT}/drop"
SHOW_COLLECTION_STATS_URL="${END_POINT}/stats"
COUNT_DOCS_URL="${END_POINT}/count"
SHOW_COLLECTION_INDEXES_URL="${END_POINT}/index"

SHOW_DB_STATS_URL="${END_POINT}/rest/games/${API_KEY}/mongo/${STAGE}/dbstats"

#command="${CURL_POST_CMD} ${REMOVE_ALL_DATA_URL}"
#echo -e "\n${command}\n"
#eval "${command}"

nuke_db() {
  echo "Nuking database...\n"

  COLLECTIONS=("script.log" "script.gameMoveList" "script.challengeData" "script.botIds" "script.gameHistory" "script.nameGeneratorData" "script.playerTagCounter" "challengeInstance" "externalAuthentication" "matchInstance" "pendingMatches" "player" "playerMessage" "playerTransactionAudit" "teamChatHistory" "teams")

  for collection in "${COLLECTIONS[@]}"
  do
    command="${CURL_POST_CMD} -F query={} https://portal.gamesparks.net/rest/games/${API_KEY}/mongo/${STAGE}/${collection}/remove"
    echo "\n\n${command}\n"
    eval "${command}"
  done
}

create_name_generator_data_collection() {
  echo "Creating nameGeneratorData collection...\n"

  NAME_GENERATOR_DATA_COLLECTION_NAME="script.nameGeneratorData";
  ADJECTIVES_DOC_ID="adjectives";
  NOUNS_DOC_ID="nouns";

  ADJECTIVES_DOC='{ "_id": "adjectives", "list": ["Able","Acute","Alien","Alive","Alone","Ample","Angry","Armed","Bad","Big","Black","Blind","Blue","Bold","Bored","Brave","Broad","Brown","Busy","Calm","Cheap","Chief","Civic","Civil","Clean","Clear","Cold","Cool","Crazy","Crude","Cruel","Dark","Dual","Eager","Easy","Evil","Exact","Fair","Fast","Fat","Fatal","Final","Fine","Firm","Fit","Fond","Free","Fresh","Fun","Funny","Giant","Glad","Gold","Good","Grand","Great","Green","Gray","Grim","Handy","Happy","Hard","Harsh","Head","Heavy","High","Holy","Hot","Huge","Ideal","Just","Keen","Key","Kind","Known","Large","Last","Latin","Lazy","Legal","Light","Live","Local","Lone","Long","Loose","Lost","Loud","Low","Loyal","Lucky","Mad","Magic","Major","Mean","Mild","Nasty","Neat","New","Nice","Noble","Noisy","Novel","Odd","Old","Other","Outer","Pale","Plain","Prime","Proud","Pure","Quick","Quiet","Rapid","Rare","Raw","Ready","Real","Rear","Red","Rich","Right","Rigid","Rival","Rough","Round","Royal","Rude","Rural","Safe","Sharp","Sheer","Short","Silly","Slim","Sly","Small","Smart","Soft","Solar","Solo","Solid","Sore","Sound","Steep","Stiff","Still","Sunny","Super","Sure","Sweet","Swift","Tall","Tense","Thick","Thin","Tight","Tiny","Top","Total","Tough","Toxic","True","Upper","Upset","Urban","Usual","Vague","Valid","Vast","Vital","Vivid","Warm","Wary","Wee","Weird","Wet","White","Wide","Wild","Wise","Wrong","Young"] }';
  NOUNS_DOC='{ "_id": "nouns", "list": ["Aardvark","Aardwolf","Acai","Aceola","Albatross","Alligator","Alpaca","Anaconda","Angelfish","Anglerfish","Ant","Anteater","Antelope","Antlion","Ape","Aphid","Apollo","Apple","Apricot","Ares","Argo","Arkantos","Armadillo","Asp","Atlas","Avocado","Baboon","Badger","Banana","Bandicoot","Barnacle","Barracuda","Basilisk","Bass","Bat","Bear","Beaver","Bedbug","Bee","Beetle","Berry","Bird","Bison","Black","Blackbird","Blue","Boa","Boar","Bobcat","Bobolink","Bonobo","Bovid","Buffalo","Bug","Bull","Bulldog","Butterfly","Buzzard","Camel","Canid","Capybara","Caracal","Cardinal","Caribou","Carp","Cat","Catfish","Cattle","Centaur","Centipede","Cephalopod","Cerberus","Chameleon","Chamois","Cheetah","Cherry","Chickadee","Chicken","Chihuahua","Chimera","Chimp","Chimpanzee","Chinchilla","Chipmunk","Chough","Clam","Clownfish","Cobra","Coconut","Cod","Coelocanth","Collie","Condor","Coral","Cormorant","Cougar","Cow","Coy","Coyote","Crab","Cranberry","Crane","Crawdad","Crayfish","Cricket","Crocodile","Crow","Cuckoo","Cucumber","Curlew","Cyclops","Damselfly","Deer","Dingo","Dinosaur","Dionysus","Dog","Dogfish","Dolphin","Donkey","Dormouse","Dotterel","Dove","Dragon","Dragonfly","Duck","Dugong","Dunlin","Eagle","Earthworm","Earwig","Echidna","Eel","Egret","Eland","Elephant","Elk","Empusa","Emu","English","Eos","Ermine","Falcon","Ferret","Fig","Finch","Firefly","Fish","Flamingo","Flea","Fly","Flyingfish","Fowl","Fox","Frog","Galago","Gaur","Gazelle","Gecko","Gerbil","Ghost","Gibbon","Gila","Giraffe","Gnat","Gnu","Goat","Goldfinch","Goldfish","Goose","Gooseberry","Gopher","Gorilla","Goshawk","Grape","Grapefruit","Grassho","Greyhound","Griffin","Grouse","Guanaco","Guineafowl","Gull","Guppy","Haddock","Hades","Halibut","Hamster","Hare","Harrier","Hawfinch","Hawk","Hedgehog","Helios","Heracles","Hercules","Hermes","Heron","Herring","Hippo","Hippogriff","Hookworm","Hornet","Horse","Hound","Human","Husky","Hydra","Hyena","Iguana","Impala","Insect","Jackal","Jackfruit","Jaguar","Jay","Jellyfish","Kangaroo","Kingfisher","Kite","Kiwi","Koala","Koi","Kouprey","Krill","Kronos","Kudu","Ladybug","Lamprey","Lapwing","Lark","Leech","Lemming","Lemon","Lemur","Leopard","Leopon","Liger","Lime","Lion","Llama","Lobster","Locust","Loon","Loris","Louse","Lungfish","Lychee","Lynx","Lyrebird","Macaw","Mackerel","Magpie","Mallard","Mammal","Mammoth","Manatee","Mango","Margay","Marlin","Marmoset","Marmot","Marsupial","Marten","Mastiff","Mastodon","Meadowlark","Medusa","Meerkat","Melon","Merekat","Mink","Minnow","Minotaur","Mite","Mole","Mollusk","Mongoose","Monkey","Monster","Moose","Mosquito","Moth","Mouse","Mudskipper","Mulberry","Mule","Mullet","Muskox","Mussel","Narwhal","Newt","Ocelot","Octopus","Okapi","Old","Opossum","Orangutan","Orca","Orion","Oryx","Ostrich","Otter","Owl","Ox","Oyster","Panda","Panther","Papaya","Parakeet","Parrot","Parrotfish","Partridge","Peach","Peacock","Peafowl","Pear","Pegasus","Pekingese","Pelican","Penguin","Perch","Peregrine","Perentie","Perseus","Pheasant","Phoenix","Pigeon","Pike","Pineapple","Pinniped","Piranha","Planarian","Platypus","Plum","Pointer","Pony","Poodle","Porcupine","Porpoise","Poseidon","Possum","PperGrouse","Prawn","Primate","Prometheus","Prune","Puffin","Puma","Python","Quail","Quelea","Rabbit","Raccoon","Rail","Ram","Raspberry","Rat","Raven","Reindeer","Rhinoceros","Roadrunner","Robin","Rodent","Rook","Rooster","Roundworm","Ruff","Sailfish","Salamander","Salmon","Sandpiper","Sardine","Sawfish","Scallop","Scorpion","Scylla","Seahorse","Seal","Serval","Setter","Shade","Shark","Sheep","Shrew","Shrimp","Silkworm","Silverfish","Skink","Sloth","Slug","Smelt","Snail","Snake","Snipe","Sole","Spaniel","Sparrow","Sphinx","Spider","Spirit","Sponge","Spoonbill","Squid","Squirrel","Starfish","Starling","Stingray","Stinkbug","Stoat","Stork","Strawberry","Sturgeon","Swan","Swift","Swordfish","Swordtail","Tahr","Takin","Tangerine","Tapeworm","Tapir","Tarantula","Tarsier","Termite","Tern","Terrier","Themis","Thrush","Tick","Tiger","Tigon","Toad","Tortoise","Toucan","Trojan","Trout","Tuna","Turkey","Turtle","Typhon","Urchin","Urial","Vampire","Vicuña","Viper","Vole","Vulture","Wallaby","Walrus","Warbler","Warthog","Wasp","Watermelon","Werewolf","Whale","Whitefish","Wildcat","Wildebeest","Wildfowl","Wolf","Wolverine","Wombat","Woodcock","Woodpecker","Worm","Wren","Yak","Zebra","Zeus"] }';

  DOCS=("${ADJECTIVES_DOC}" "${NOUNS_DOC}")

  for doc in "${DOCS[@]}"
  do
    command="${CURL_POST_CMD} -F document='${doc}' https://portal.gamesparks.net/rest/games/${API_KEY}/mongo/${STAGE}/${NAME_GENERATOR_DATA_COLLECTION_NAME}/insert"
    echo "\n${command}\n"
    eval "${command}"
  done
}

create_player_tag_counter_collection() {
  echo "Creating playerTagCounter collection...\n"

  PLAYER_TAG_COUNTER_COLLECTION_NAME="script.playerTagCounter";
  DOC='{ "_id": "playerTagCounter", "counter": 0 }'

  command="${CURL_POST_CMD} -F document='${DOC}' https://portal.gamesparks.net/rest/games/${API_KEY}/mongo/${STAGE}/${PLAYER_TAG_COUNTER_COLLECTION_NAME}/insert"
  echo "\n${command}\n"
  eval "${command}"
}

# We don't know how to send log event requests via rest API yet...
#create_bots() {
# echo "Creating bots...\n"
##
# command="${CURL_POST_CMD} --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{ \"@class\": \".LogEventRequest\", \"eventKey\": \"DEV_InitBot\", \"count\": 100 }' 'https://v304295caXB2.preview.gamesparks.net/rs/nukescript/Pzm0XkFKzfaZgPVvXvzxirVu0slXlzXg/LogEventRequest'"
# echo "\n${command}\n"
# eval "${command}"
#}


init_db() {
  echo -e "Initializing database...\n"

  create_name_generator_data_collection
  create_player_tag_counter_collection

}

nuke_db
init_db
