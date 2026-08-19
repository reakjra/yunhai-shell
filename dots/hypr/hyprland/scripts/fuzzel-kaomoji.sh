#!/bin/bash
set -euo pipefail

MODE="${1:-type}"

kaomoji="$(sed '1,/^### DATA ###$/d' "$0" | fuzzel --match-mode fzf --dmenu | cut -f 1 | tr -d '\n')"

case "$MODE" in
    type)
        wtype "${kaomoji}" || wl-copy "${kaomoji}"
        ;;
    copy)
        wl-copy "${kaomoji}"
        ;;
    both)
        wtype "${kaomoji}" || true
        wl-copy "${kaomoji}"
        ;;
    *)
        echo "Usage: $0 [type|copy|both]"
        exit 1
        ;;
esac

exit
### DATA ###
(^_^)	happy smile cute cheerful
(^-^)	happy smile gentle
(＾▽＾)	happy grinning bright joy
(◕‿◕)	happy cute sweet smile
(☆▽☆)	star eyes excited amazed impressed
(⌒▽⌒)	happy smile warm cheerful
( ´ ▽ ` )	happy relaxed cheerful
(*^ω^*)	happy excited cute blushing
(´∀｀*)	happy laughing pleased
(o^▽^o)	happy cheerful bright face
(⌒▽⌒)☆	happy star cheerful
<(￣︶￣)>	content satisfied smug pleased
(ﾉ◕ヮ◕)ﾉ	excited throwing happy raising arms
(o･ω･o)	cute neutral face soft
(๑˃ᴗ˂)ﻭ	determined happy fist pump yes
(☆ω☆)	star eyes cute excited
٩(◕‿◕｡)۶	celebrating happy excited cute
ヽ(・∀・)ﾉ	wave happy excited hello
＼(￣▽￣)／	celebrating happy yay excited
(*¯︶¯*)	content satisfied pleased comfortable
(っ˘ω˘ς )	cozy sleepy comfortable cute
(❁´◡`❁)	flower cute happy sweet
(≧◡≦)	happy cute grin joyful
( ´ ▽ ` )ﾉ	wave hello happy greeting
✧*。٩(ˊωˋ*)و✧*。	sparkle determined motivated fighting
(ﾉ>ω<)ﾉ :｡･:*:･ﾟ'★,｡･:*:･ﾟ'☆	sparkle magic celebration stars
(*≧ω≦)	excited happy giddy thrilled
(✿◠‿◠)	flower happy cute sweet
(◕ᴗ◕✿)	flower cute adorable sweet
(*´▽`*)	happy blushing sweet cheerful
(ﾟヮﾟ)	happy excited elated cute
(♡-_-♡)	love hearts dreamy affection
(─‿‿─)	content happy gentle warm
(ﾉ´ з `)ノ	kiss love blow affection
(♡μ_μ)	love shy hearts affection
(*^^*)♡	blushing love happy heart
(⁄ ⁄•⁄ω⁄•⁄ ⁄)	blushing shy embarrassed flustered
(づ￣ ³￣)づ	kiss hug love grabby
(つ≧▽≦)つ	hug embrace happy excited
(っ´▽｀)っ	hug embrace come here
( ˘⌣˘)♡(˘⌣˘ )	couple love hearts together
(/^-^(^ ^*)/ ♡	couple hug love hearts
(♡˙︶˙♡)	love content happy hearts
(灬º‿º灬)♡	love blushing happy heart
♡＼(￣▽￣)／♡	love celebrating hearts happy
(ღ˘⌣˘ღ)	love hearts content happy
(♡°▽°♡)	love excited happy hearts
♡( ◡‿◡ )	love peaceful happy heart
(´• ω •`) ♡	cute love soft heart
(⌒_⌒;)	nervous embarrassed awkward sweat
(*ﾉωﾉ)	shy hiding embarrassed covering face
(///￣ ￣///)	blushing embarrassed shy flustered
(˶>⩊<˶)	shy cute blushing squished
(〃▽〃)	blushing happy shy cute
(*/ω＼*)	shy embarrassed hiding blushing
(T_T)	crying sad tears upset
(;_;)	crying sad tears face
(ToT)	crying bawling sad tears
(v_v)	sad downcast depressed
(×_×)	dead defeated knocked out
( ╥ω╥ )	crying sad tears emotional
(个_个)	sad eyes teary
(ಥ_ಥ)	crying sad tears upset face
(╥_╥)	crying sad tears
(oT-T)o	crying reaching sad
(；￣Д￣)	frustrated sad upset annoyed
( ；∀；)	crying laughing emotional tears
(ノ_<。)	crying face hiding tears
(╯︵╰,)	sad frown upset down
(︶︹︺)	sad frown unhappy down
(╥﹏╥)	crying sad tears upset
(ﾉД`)	crying upset sad tears
(⊃ω・)	peeking shy one eye
(｡•́︿•̀｡)	sad worried upset face
(っ- ‸ - ς)	sad hugging self comfort
(๑◕︵◕๑)	sad cute teary pouty
(⌣_⌣")	worried sad concerned
(;ω;)	crying sad tears
(´;ω;`)	crying sad hurt tears
。゜゜(´Ｏ`) ゜゜。	wailing crying loud sad
(ó﹏ò)	worried anxious nervous scared
(´-ω-`)	sad tired dejected down
(ᗒᗣᗕ)՞	crying upset ugly cry bawling
(∩︵∩)	sad crying hiding face
(☍﹏⁰)	teary worried about to cry
(>_<)	angry frustrated annoyed
(-_-)	annoyed bored unimpressed deadpan
(¬_¬)	side eye annoyed suspicious skeptical
(￣^￣)	annoyed determined stern
(ノ°益°)ノ 彡 ┻━┻	table flip angry rage
┬─┬ノ( º _ ºノ)	putting table back calm unflip
(ง ͠° ͟ل͜ ͡°)ง	fight ready boxing fists
ᕙ(⇀‸↼‶)ᕗ	flexing strong muscles tough
ᕦ(ò_óˇ)ᕤ	flexing strong determined muscles
(╯°□°）╯︵ ┻━┻	table flip angry rage frustrated
(┛◉Д◉)┛彡┻━┻	table flip angry furious shocked
(ノಠ益ಠ)ノ彡┻━┻	table flip angry rage disapproval
( ಠ 益 ಠ )	angry stare furious rage
(>人<)	frustrated annoyed upset
(　ﾟДﾟ)＜!!	shocked yelling angry surprised
(╬ Ò﹏Ó)	angry furious mad rage
(°ㅂ° ╬)	angry intense furious
(‡▼益▼)	angry menacing furious evil
(҂⌣̀_⌣́)	angry threatening intense
(｀ε´)	pouting annoyed grumpy
(￣□￣」)	shocked angry surprised yelling
(╬ಠ益ಠ)	angry furious disapproval rage
(ノ°Д°)ノ	angry shocked throwing
(＃`Д´)	angry frustrated yelling furious
(ーー;)	annoyed frustrated bothered
(ง'̀-'́)ง	fight boxing fists ready determined
(o_o)	confused blank surprised
(@_@)	dizzy confused overwhelmed spinning
(O_O)	shocked surprised wide eyes
(._.)	blank quiet neutral small
(☆_@)	dizzy confused star struck
(º _ º)	blank stare neutral confused
(°ロ°) !	shocked surprised alarm realization
(⊙_⊙)	shocked surprised wide eyes
(O.O)	surprised shocked wide eyes
(゜-゜)	blank stare confused lost
(・_・;)	confused nervous uncertain sweat
(￣◇￣;)	confused surprised open mouth
(°0°)	surprised shocked open mouth
(°_o)	confused skeptical uncertain
( ´_ゝ`)	unimpressed bored deadpan
(￢_￢;)	skeptical suspicious thinking sweat
(≖_≖ )	suspicious skeptical judging flat
(・へ・)	confused unhappy uncertain
(￣～￣;)	thinking confused uncertain hmm
( • _ • )	blank stare neutral deadpan
(ﾟヘﾟ)	confused puzzled uncertain
Σ(°△°|||)	shocked surprise gasp startled
(ﾟДﾟ)	shocked horrified surprised stunned
w(°ｏ°)w	amazed wow surprised impressed
(ﾟoﾟ)	surprised wow amazed
(○_○)	shocked blank wide eyes surprised
Σ(ﾟДﾟ)	shock surprise realization gasp
!!(ﾟロﾟ屮)屮	shock surprise oh no
(◎_◎;)	shocked wide eyes surprised amazed
( ͡° ͜ʖ ͡°)	lenny face smug suggestive meme
¯\_(ツ)_/¯	shrug whatever idk dunno
(￣ω￣)	content hmm satisfied smug
( ͡° ᴥ ͡°)	smug animal face lenny
( ͡~ ͜ʖ ͡°)	wink smug lenny suggestive
( ˘▽˘)っ♨	serving tea offering smug
┐(￣ヘ￣)┌	shrug indifferent whatever
╮(︶▽︶)╭	shrug happy whatever carefree
┐( ˘_˘)┌	shrug indifferent meh
╮(￣_￣)╭	shrug whatever meh
┐(￣～￣)┌	shrug thinking whatever hmm
(￣ー￣)	smug cool satisfied
( ´ ꒳ ` )	cute content happy soft
(￢‿￢ )	smug sly knowing
(¬‿¬ )	smug sly mischievous
( ‾́ ◡ ‾́ )	smug proud satisfied
(︶▽︶)	content smug happy peaceful
( ಠ ͜ʖ ಠ)	lenny serious smug stare
( ✧≖ ͜ʖ≖)	lenny cool sparkle smug
( ͡ᵔ ͜ʖ ͡ᵔ )	lenny cute smug
( ͡^ ͜ʖ ͡^ )	lenny happy smug
( ͡ಠ ʖ̯ ͡ಠ)	lenny disapproval serious
ಠ_ಠ	disapproval stare judging look
ಠ‿ಠ	creepy smile disturbing happy
(눈_눈)	judging suspicious skeptical stare
(=^･ω･^=)	cat cute meow kitty
(=①ω①=)	cat cute face kitty
(=^･ｪ･^=)	cat cute meow face
(=^・・^=)	cat cute face kitty
(=^. .^=)	cat cute face
( =ω= )	cat content relaxed purring
(=`ω´=)	cat angry fierce hiss
ʕ ᵔᴥᵔ ʔ	bear cute animal happy
ʕ •ᴥ• ʔ	bear cute animal face
ʕ •̀ o •́ ʔ	bear surprised shocked animal
ʕ •̀ ω •́ ʔ	bear determined fierce animal
U・ᴥ・U	dog cute animal puppy
V●ᴥ●V	dog cute animal puppy face
U ´ᴥ` U	dog happy cute animal
(ᵔᴥᵔ)	dog cute animal happy
(・θ・)	bird chick cute animal
( 0 x 0 )	bunny rabbit cute animal
(・x・)	bunny rabbit cute animal
( U・x・U )	bunny rabbit cute fluffy
( ˘(ｴ)˘)	bear sleepy cute animal
(*￣(ｴ)￣*)	bear happy cute animal
ʕ╥ᴥ╥ʔ	bear crying sad animal
(^_~)	wink playful cute
(^_-)	wink playful
( -_・)	wink cool sly
(^_<)〜☆	wink star playful magic
(>ω^)	wink happy playful
(^ω~)	wink cute happy
(*・ω・)ﾉ	wave hello hi greeting
(×_×)⌒☆	knocked out star dead defeated
( ^_^)／	wave hello greeting hi
( ﾟ▽ﾟ)/	wave excited hello greeting
(・_・)ノ	wave hello neutral greeting
(￣▽￣)ノ	wave hello happy greeting
(・∀・)ノ	wave hello cheerful greeting
(＠´ー`)ﾉﾞ	wave cool greeting hello
(*°ｰ°)ﾉ	wave hello calm greeting
(^-^*)/	wave hello happy shy
( ° ∀ ° )ﾉﾞ	wave hello excited greeting
( ´ ∀ ` )ﾉ	wave hello cheerful greeting
(☞ﾟ∀ﾟ)☞	pointing finger guns cool confident
(☞ﾟヮﾟ)☞	pointing happy finger guns excited
☜(ﾟヮﾟ☜)	pointing left finger guns cool
(つ✧ω✧)つ	grabby hands sparkle want excited
⊂(・▽・⊂)	hug come here embrace
(⊃｡•́‿•̀｡)⊃	hug comfort caring embrace
(っ˘̩╭╮˘̩)っ	hug comfort sad caring
( ˘ω˘ )	sleepy tired peaceful calm
(∪｡∪)｡｡｡zzZ	sleeping tired zzz nap rest
(-ω-) zzZ	sleeping napping tired
(ᴗ˳ᴗ)	peaceful sleeping calm relaxed
(─‿─)	calm content peaceful relaxed
(*´ω`*)	cozy warm content comfortable
(´ε`*)	kiss love affection smooch
(ﾉ´з`)ノ	kiss love blow affection
(´∀`)♡	love happy heart affection
(✧ω✧)	sparkle eyes excited amazed
(•̀ᴗ•́)و	determined yes success fist pump
(ง •̀_•́)ง	fighting determined ready go
(￣^￣)ゞ	salute yes sir determined
(；一_一)	tired exhausted done over it
_(:3」∠)_	lying down tired lazy done defeated
orz	bowing defeated frustration
OTL	bowing defeated frustration ground
m(_ _)m	bowing apology sorry respect
(人´∀`)	please begging asking favor
(；人；)	begging please desperate sorry
ε=ε=ε=ε=┌(;￣▽￣)┘	running away fleeing escape hurry
─=≡Σ((( つ◕ل͜◕)つ	running towards charging rushing
♪(´ε`)	singing music happy humming
♪～(´ε`～)	dancing singing happy music
₍₍ (ง ˙ω˙)ว ⁾⁾	dancing wiggle happy excited
ヾ(⌐■_■)ノ♪	cool dancing music sunglasses
ヽ(>∀<☆)ノ	excited celebrating star happy
ヽ(´▽`)/	celebrating happy yay
(ノ^_^)ノ	throwing happy excited celebrate
(o´▽`o)	happy cute cheerful bright
(^-^*)	happy shy cute cheerful
( ˘ ³˘)♥	kiss love smooch heart
(੭ˊᵕˋ)੭	cute tiny happy little
(ﾉ´ヮ`)ﾉ*:・゚✧	sparkle magic celebrate throwing stars
♡(◕ᗜ◕✿)	love flower cute happy adorable
(ﾉ´∀`*)ﾉ	excited happy throwing celebrate
(^///^)	blushing shy embarrassed cute
(´,,•ω•,,)	shy blushing nervous cute
(,,>﹏<,,)	blushing embarrassed nervous
( ˊᵕˋ )	gentle soft happy sweet
(⺣◡⺣)♡	love content happy dreamy
(｡♥‿♥｡)	love hearts eyes adore
(ᵕ̣̣̣̣̣̣ ω ᵕ̣̣̣̣̣̣)	soft gentle sad cute
(◡ ω ◡)	peaceful content happy calm
(꒪˙꒳˙꒪)	confused curious surprised
╰(*´︶`*)╯	happy celebrating arms up yay
(≧∀≦)ゞ	happy excited salute cheerful
(✿ヘᴥヘ)	cute flower animal pouty
ψ(｀∇´)ψ	evil mischievous devil scheming
(☄ฺ◣д◢)☄ฺ	angry intense furious fire
(ꈍᴗꈍ)	cute happy soft sweet
ᐠ( ᐛ )ᐟ	spider creature creepy cute
