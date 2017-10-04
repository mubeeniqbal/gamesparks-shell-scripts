#!/bin/bash
#
# REST API documentation:
# https://docs.gamesparks.com/api-documentation/nosql-rest-api.html
#
# This script has a dependency on jq: https://stedolan.github.io/jq/
# Make sure jq is installed on your system and is present in PATH.

### Colors ###

readonly RC='\033[0m' # Reset color

readonly BLACK='\033[0;30m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'

readonly BRIGHT_BLACK='\033[1;30m'
readonly BRIGHT_RED='\033[1;31m'
readonly BRIGHT_GREEN='\033[1;32m'
readonly BRIGHT_YELLOW='\033[1;33m'
readonly BRIGHT_BLUE='\033[1;34m'
readonly BRIGHT_MAGENTA='\033[1;35m'
readonly BRIGHT_CYAN='\033[1;36m'
readonly BRIGHT_WHITE='\033[1;37m'

### End Colors ###

readonly AUTH_URL='https://auth.gamesparks.net'
readonly CONFIG_URL='https://config2.gamesparks.net'

# Fill in these fields before using this script.
readonly USERNAME=''
readonly PASSWORD=''
readonly API_KEY=''
readonly STAGE=''

declare -a SYSTEM_COLLECTIONS
declare -a RUNTIME_COLLECTIONS

STAGE_BASE_URL=''
JWT=''

discover_endpoints() {
  echo -e "${MAGENTA}Discovering endpoints...${RC}\n"

  local command="curl --silent --user ${USERNAME}:${PASSWORD} -X GET --header 'Accept: application/json' ${CONFIG_URL}/restv2/game/${API_KEY}/endpoints"
  echo -e "> ${CYAN}${command}${RC}\n"

  local response
  response="$(eval "${command}")"

  # Pretty print JSON reponse
  eval "echo '${response}' | jq '.'"

  # Use jq --raw-output to remove get string without quotes.
  command="echo '${response}' | jq --raw-output '.${STAGE}Nosql'"
  STAGE_BASE_URL="$(eval "${command}")"
  readonly STAGE_BASE_URL
  echo -e "\n${YELLOW}Stage Base URL: ${STAGE_BASE_URL}${RC}"
}

auth_nosql() {
  echo -e "${MAGENTA}Authenticating user to access NoSQL database...${RC}\n"

  local filter='nosql'
  local command="curl --silent --user ${USERNAME}:${PASSWORD} -X GET --header 'Accept: application/json' ${AUTH_URL}/restv2/auth/game/${API_KEY}/jwt/${filter}"
  echo -e "> ${CYAN}${command}${RC}\n"

  local response
  response="$(eval "${command}")"

  # Pretty print JSON reponse
  eval "echo '${response}' | jq '.'"

  # Use jq --raw-output to remove get string without quotes.
  command="echo '${response}' | jq --raw-output '.\"X-GS-JWT\"'"
  JWT="$(eval "${command}")"
  readonly JWT
  echo -e "\n${YELLOW}JSON Web Token: ${JWT}${RC}"
}

list_collections() {
  echo -e "${MAGENTA}Listing NoSQL database collections...${RC}\n"

  local filter='nosql'
  local command="curl --silent -X GET --header 'Accept: application/json' --header 'X-GS-JWT: ${JWT}' ${STAGE_BASE_URL}/restv2/game/${API_KEY}/mongo/collections"
  echo -e "> ${CYAN}${command}${RC}\n"

  local response
  response="$(eval "${command}")"

  # Pretty print JSON reponse
  eval "echo '${response}' | jq '.'"

  # System collections

  # Use jq --raw-output to remove get string without quotes.
  # We base64 encode to get rid of spaces and newlines. Later on we will
  # base64 decode all the values.
  command="echo '${response}' | jq --raw-output '.[] | select(.optionGroup == \"System\") | .name | @base64'"

  local collection
  unset SYSTEM_COLLECTIONS

  for collection_base64 in $(eval "${command}")
  do
    # We have to output this way to append newline character at the end.
    collection="$(echo "$(echo "${collection_base64}" | base64 --decode)")"
    SYSTEM_COLLECTIONS+=("${collection}")
  done

  echo -e "\n${YELLOW}System Collections: ${SYSTEM_COLLECTIONS[*]}${RC}"

  # Runtime collections

  # Use jq --raw-output to remove get string without quotes.
  # We base64 encode to get rid of spaces and newlines. Later on we will
  # base64 decode all the values.
  command="echo '${response}' | jq --raw-output '.[] | select(.optionGroup == \"Runtime\") | .name | @base64'"

  unset RUNTIME_COLLECTIONS

  for collection_base64 in $(eval "${command}")
  do
    # We have to output this way to append newline character at the end.
    collection="$(echo "$(echo "${collection_base64}" | base64 --decode)")"
    RUNTIME_COLLECTIONS+=("${collection}")
  done

  echo -e "\n${YELLOW}Runtime Collections: ${RUNTIME_COLLECTIONS[*]}${RC}"

  # TODO(mubeeniqbal): Add Meta, Leaderboards and Running Totals collections.
}

remove_system_collection_documents() {
  echo -e "${MAGENTA}Removing documents from system collections...${RC}"

  for collection in "${SYSTEM_COLLECTIONS[@]}"
  do
    echo -e "\n${YELLOW}Removing all documents from collection '${collection}' ...${RC}\n"

    local command="curl --silent -X POST --header 'Content-Type: application/json;charset=UTF-8' --header 'Accept: application/json' --header 'X-GS-JWT: ${JWT}' -d '{ \"query\": {} }' ${STAGE_BASE_URL}/restv2/game/${API_KEY}/mongo/collection/${collection}/remove"
    echo -e "> ${CYAN}${command}${RC}\n"

    local response
    response="$(eval "${command}")"

    # Pretty print JSON reponse
    eval "echo '${response}' | jq '.'"
  done
}

delete_runtime_collections() {
  echo -e "${MAGENTA}Deleting runtime collections...${RC}"

  for collection in "${RUNTIME_COLLECTIONS[@]}"
  do
    echo -e "\n${YELLOW}Deleting collection '${collection}' ...${RC}\n"

    local command="curl --silent -X DELETE --header 'Accept: application/json' --header 'X-GS-JWT: ${JWT}' ${STAGE_BASE_URL}/restv2/game/${API_KEY}/mongo/collection/${collection}"
    echo -e "> ${CYAN}${command}${RC}\n"

    local response
    response="$(eval "${command}")"

    # Pretty print JSON reponse
    eval "echo '${response}' | jq '.'"
  done
}

nuke_nosql() {
  remove_system_collection_documents
  echo -e '\n--------------------\n'
  delete_runtime_collections
}

create_name_generator_data_collection() {
  local COLLECTION="nameGeneratorData";

  echo -e "${MAGENTA}Creating runtime collection 'script.${COLLECTION}' ...${RC}\n"

  local command="curl --silent -X POST --header 'Content-Type: application/json;charset=UTF-8' --header 'Accept: application/json' --header 'X-GS-JWT: ${JWT}' ${STAGE_BASE_URL}/restv2/game/${API_KEY}/mongo/collection/${COLLECTION}/runtime"
  echo -e "> ${CYAN}${command}${RC}\n"

  local response
  response="$(eval "${command}")"

  # Pretty print JSON reponse
  eval "echo '${response}' | jq '.'"

  local ADJECTIVES_DOCUMENT='{ "_id": "adjectives", "list": ["Able","Acute","Alien","Alive","Alone","Ample","Angry","Armed","Bad","Big","Black","Blind","Blue","Bold","Bored","Brave","Broad","Brown","Busy","Calm","Cheap","Chief","Civic","Civil","Clean","Clear","Cold","Cool","Crazy","Crude","Cruel","Dark","Dual","Eager","Easy","Evil","Exact","Fair","Fast","Fat","Fatal","Final","Fine","Firm","Fit","Fond","Free","Fresh","Fun","Funny","Giant","Glad","Gold","Good","Grand","Great","Green","Gray","Grim","Handy","Happy","Hard","Harsh","Head","Heavy","High","Holy","Hot","Huge","Ideal","Just","Keen","Key","Kind","Known","Large","Last","Latin","Lazy","Legal","Light","Live","Local","Lone","Long","Loose","Lost","Loud","Low","Loyal","Lucky","Mad","Magic","Major","Mean","Mild","Nasty","Neat","New","Nice","Noble","Noisy","Novel","Odd","Old","Other","Outer","Pale","Plain","Prime","Proud","Pure","Quick","Quiet","Rapid","Rare","Raw","Ready","Real","Rear","Red","Rich","Right","Rigid","Rival","Rough","Round","Royal","Rude","Rural","Safe","Sharp","Sheer","Short","Silly","Slim","Sly","Small","Smart","Soft","Solar","Solo","Solid","Sore","Sound","Steep","Stiff","Still","Sunny","Super","Sure","Sweet","Swift","Tall","Tense","Thick","Thin","Tight","Tiny","Top","Total","Tough","Toxic","True","Upper","Upset","Urban","Usual","Vague","Valid","Vast","Vital","Vivid","Warm","Wary","Wee","Weird","Wet","White","Wide","Wild","Wise","Wrong","Young"] }';
  local NOUNS_DOCUMENT='{ "_id": "nouns", "list": ["Aardvark","Aardwolf","Acai","Aceola","Albatross","Alligator","Alpaca","Anaconda","Angelfish","Anglerfish","Ant","Anteater","Antelope","Antlion","Ape","Aphid","Apollo","Apple","Apricot","Ares","Argo","Arkantos","Armadillo","Asp","Atlas","Avocado","Baboon","Badger","Banana","Bandicoot","Barnacle","Barracuda","Basilisk","Bass","Bat","Bear","Beaver","Bedbug","Bee","Beetle","Berry","Bird","Bison","Black","Blackbird","Blue","Boa","Boar","Bobcat","Bobolink","Bonobo","Bovid","Buffalo","Bug","Bull","Bulldog","Butterfly","Buzzard","Camel","Canid","Capybara","Caracal","Cardinal","Caribou","Carp","Cat","Catfish","Cattle","Centaur","Centipede","Cephalopod","Cerberus","Chameleon","Chamois","Cheetah","Cherry","Chickadee","Chicken","Chihuahua","Chimera","Chimp","Chimpanzee","Chinchilla","Chipmunk","Chough","Clam","Clownfish","Cobra","Coconut","Cod","Coelocanth","Collie","Condor","Coral","Cormorant","Cougar","Cow","Coy","Coyote","Crab","Cranberry","Crane","Crawdad","Crayfish","Cricket","Crocodile","Crow","Cuckoo","Cucumber","Curlew","Cyclops","Damselfly","Deer","Dingo","Dinosaur","Dionysus","Dog","Dogfish","Dolphin","Donkey","Dormouse","Dotterel","Dove","Dragon","Dragonfly","Duck","Dugong","Dunlin","Eagle","Earthworm","Earwig","Echidna","Eel","Egret","Eland","Elephant","Elk","Empusa","Emu","English","Eos","Ermine","Falcon","Ferret","Fig","Finch","Firefly","Fish","Flamingo","Flea","Fly","Flyingfish","Fowl","Fox","Frog","Galago","Gaur","Gazelle","Gecko","Gerbil","Ghost","Gibbon","Gila","Giraffe","Gnat","Gnu","Goat","Goldfinch","Goldfish","Goose","Gooseberry","Gopher","Gorilla","Goshawk","Grape","Grapefruit","Grassho","Greyhound","Griffin","Grouse","Guanaco","Guineafowl","Gull","Guppy","Haddock","Hades","Halibut","Hamster","Hare","Harrier","Hawfinch","Hawk","Hedgehog","Helios","Heracles","Hercules","Hermes","Heron","Herring","Hippo","Hippogriff","Hookworm","Hornet","Horse","Hound","Human","Husky","Hydra","Hyena","Iguana","Impala","Insect","Jackal","Jackfruit","Jaguar","Jay","Jellyfish","Kangaroo","Kingfisher","Kite","Kiwi","Koala","Koi","Kouprey","Krill","Kronos","Kudu","Ladybug","Lamprey","Lapwing","Lark","Leech","Lemming","Lemon","Lemur","Leopard","Leopon","Liger","Lime","Lion","Llama","Lobster","Locust","Loon","Loris","Louse","Lungfish","Lychee","Lynx","Lyrebird","Macaw","Mackerel","Magpie","Mallard","Mammal","Mammoth","Manatee","Mango","Margay","Marlin","Marmoset","Marmot","Marsupial","Marten","Mastiff","Mastodon","Meadowlark","Medusa","Meerkat","Melon","Merekat","Mink","Minnow","Minotaur","Mite","Mole","Mollusk","Mongoose","Monkey","Monster","Moose","Mosquito","Moth","Mouse","Mudskipper","Mulberry","Mule","Mullet","Muskox","Mussel","Narwhal","Newt","Ocelot","Octopus","Okapi","Old","Opossum","Orangutan","Orca","Orion","Oryx","Ostrich","Otter","Owl","Ox","Oyster","Panda","Panther","Papaya","Parakeet","Parrot","Parrotfish","Partridge","Peach","Peacock","Peafowl","Pear","Pegasus","Pekingese","Pelican","Penguin","Perch","Peregrine","Perentie","Perseus","Pheasant","Phoenix","Pigeon","Pike","Pineapple","Pinniped","Piranha","Planarian","Platypus","Plum","Pointer","Pony","Poodle","Porcupine","Porpoise","Poseidon","Possum","PperGrouse","Prawn","Primate","Prometheus","Prune","Puffin","Puma","Python","Quail","Quelea","Rabbit","Raccoon","Rail","Ram","Raspberry","Rat","Raven","Reindeer","Rhinoceros","Roadrunner","Robin","Rodent","Rook","Rooster","Roundworm","Ruff","Sailfish","Salamander","Salmon","Sandpiper","Sardine","Sawfish","Scallop","Scorpion","Scylla","Seahorse","Seal","Serval","Setter","Shade","Shark","Sheep","Shrew","Shrimp","Silkworm","Silverfish","Skink","Sloth","Slug","Smelt","Snail","Snake","Snipe","Sole","Spaniel","Sparrow","Sphinx","Spider","Spirit","Sponge","Spoonbill","Squid","Squirrel","Starfish","Starling","Stingray","Stinkbug","Stoat","Stork","Strawberry","Sturgeon","Swan","Swift","Swordfish","Swordtail","Tahr","Takin","Tangerine","Tapeworm","Tapir","Tarantula","Tarsier","Termite","Tern","Terrier","Themis","Thrush","Tick","Tiger","Tigon","Toad","Tortoise","Toucan","Trojan","Trout","Tuna","Turkey","Turtle","Typhon","Urchin","Urial","Vampire","Vicuña","Viper","Vole","Vulture","Wallaby","Walrus","Warbler","Warthog","Wasp","Watermelon","Werewolf","Whale","Whitefish","Wildcat","Wildebeest","Wildfowl","Wolf","Wolverine","Wombat","Woodcock","Woodpecker","Worm","Wren","Yak","Zebra","Zeus"] }';

  local DOCUMENTS=("${ADJECTIVES_DOCUMENT}" "${NOUNS_DOCUMENT}")

  for document in "${DOCUMENTS[@]}"
  do
    echo -e "\n${YELLOW}Inserting document '${document:0:50}...' ...${RC}\n"

    local command="curl --silent -X POST --header 'Content-Type: application/json;charset=UTF-8' --header 'Accept: application/json;charset=UTF-8' --header 'X-GS-JWT: ${JWT}' -d '${document}' ${STAGE_BASE_URL}/restv2/game/${API_KEY}/mongo/collection/script.${COLLECTION}/insert"
    echo -e "> ${CYAN}${command}${RC}\n"

    local response
    response="$(eval "${command}")"

    # Pretty print JSON reponse
    eval "echo '${response}' | jq '.'"
  done
}

init_nosql() {
  echo -e "${MAGENTA}Initializing NoSQL database...${RC}\n"

  create_name_generator_data_collection
}

discover_endpoints
echo -e '\n--------------------\n'
auth_nosql
echo -e '\n--------------------\n'
list_collections
echo -e '\n--------------------\n'
nuke_nosql
echo -e '\n--------------------\n'
init_nosql
