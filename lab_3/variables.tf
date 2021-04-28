variable "my_panda" {
  default     = "happy-panda"
  description = "The name of your panda (provided with environment) i.e. happy-panda"
}

variable "env_vars" {
  type = map(string)
  default = {
    ANIMALS = "ox,ant,ape,asp,bat,bee,boa,bug,cat,cod,cow,cub,doe,dog,eel,eft,elf,elk,emu,ewe,fly,fox,gar,gnu,hen,hog,imp,jay,kid,kit,koi,lab,man,owl,pig,pug,pup,ram,rat,ray,yak,bass,bear,bird,boar,buck,bull,calf,chow,clam,colt,crab,crow,dane,deer,dodo,dory,dove,drum,duck,fawn,fish,flea,foal,fowl,frog,gnat,goat,grub,gull,hare,hawk,ibex,joey,kite,kiwi,lamb,lark,lion,loon,lynx,mako,mink,mite,mole,moth,mule,mutt,newt,orca,oryx,pika,pony,puma,seal,shad,slug,sole,stag,stud,swan,tahr,teal,tick,toad,tuna,wasp,wolf,worm,wren,yeti,adder,akita,alien,aphid,bison,boxer,bream,bunny,burro,camel,chimp,civet,cobra,coral,corgi,crane,dingo,drake,eagle,egret,filly,finch,gator,gecko,ghost,ghoul,goose,guppy,heron,hippo,horse,hound,husky,hyena,koala,krill,leech,lemur,liger,llama,louse,macaw,midge,molly,moose,moray,mouse,panda,perch,prawn,quail,racer,raven,rhino,robin,satyr,shark,sheep,shrew,skink,skunk,sloth,snail,snake,snipe,squid,stork,swift,swine,tapir,tetra,tiger,troll,trout,viper,wahoo,whale,zebra,alpaca,amoeba,baboon,badger,beagle,bedbug,beetle,bengal,bobcat,caiman,cattle,cicada,collie,condor,cougar,coyote,dassie,donkey,dragon,earwig,falcon,feline,ferret,gannet,gibbon,glider,goblin,gopher,grouse,guine"
  }
  description = "The enviroment variables for the function"
}