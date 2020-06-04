arch snes.cpu

// LoROM org macro - see bass's snes-cpu.asm "seek" macro
macro reorg n
	org (({n} & 0x7F0000) >> 1) | ({n} & 0x7FFF)
	base {n}
endmacro

// Allows going back and forth
define savepc push origin, base
define loadpc pull base, origin

// Copy the original ROM
{reorg $008000}
incbin "Rockman X 2 (J).smc"


// Constants
eval game_config_size $1B
// Version tags
eval version_major 1
eval version_minor 3
eval version_revision 0
// RAM addresses
eval config_selected_option $7EFF80
eval load_temporary_rng $7F0000
eval rng_value $7E09D6
eval title_screen_option $7E003C
eval controller_1_current $7E00A8
eval controller_1_previous $7E00AA
eval controller_1_new $7E00AC
eval controller_2_current $7E00AE
eval controller_2_previous $7E00B0
eval controller_2_new $7E00B2
eval screen_control_shadow $7E00B4
eval nmi_control_shadow $7E00C3
eval hdma_control_shadow $7E00C4
eval current_play_state $7E00D2
eval countdown_play_state $7E00D6
eval controller_1_disable $7E1F63
eval unknown_level_flag $7E1EBF
eval state_vars $7E1FA0
eval current_level $7E1FAD
eval xhunter_level $7E1FAE
eval life_count $7E1FB3
eval spc_state_shadow $7EFFFE
eval ram_nmi_after_controller $7E25DB //Code copied from ROM
// ROM addresses
eval rom_play_sound $008549
eval rom_nmi_after_controller $0885DB
eval rom_nmi_after_pushes $7E200B  // Rockman X2 has its NMI handler in RAM
eval rom_rtl_instruction $808464  // last instruction of rom_play_sound
eval rom_config_button $80EB6D
eval rom_config_stereo $80EC00
eval rom_config_exit $80EC48
eval rom_string_table $868C6F
eval rom_string_table_unused $868D19
eval rom_string_table_end $868D59 // // one past the end of rom_string_table
eval rom_bank84_string_table $84FF00  // where to put the master string table (free space in ROM)
// Constants derived from ROM addresses
eval num_used_string_table ({rom_string_table_unused} - {rom_string_table}) / 2
// SRAM addresses for saved states
eval sram_start $700000
eval sram_previous_command $700200
eval sram_wram_7E0000 $710000
eval sram_wram_7E8000 $720000
eval sram_wram_7F0000 $730000
eval sram_wram_7F8000 $740000
eval sram_vram_0000 $750000
eval sram_vram_8000 $760000
eval sram_cgram $772000
eval sram_dma_bank $770000
eval sram_validity $774000
eval sram_saved_sp $774004
eval sram_saved_dp $774006
eval sram_vm_return $774006
eval sram_size $080000
eval sram_banks $08
// SRAM addresses for general config.  These are at lower addresses to support
// emulators and cartridges that don't support 256 KB of SRAM.
eval sram_config_valid $700100
eval sram_config_game $700104   // Main game config.  game_config_size bytes.
eval sram_config_extra {sram_config_game} + {game_config_size}
//eval sram_config_category {sram_config_extra} + 0
//eval sram_config_route {sram_config_extra} + 1
//eval sram_config_midpointsoff {sram_config_extra} + 2
eval sram_config_keeprng {sram_config_extra} + 0
//eval sram_config_musicoff {sram_config_extra} + 4
//eval sram_config_godmode {sram_config_extra} + 5
//eval sram_config_fixdrop {sram_config_extra} + 6
//eval sram_config_delay {sram_config_extra} + 7
eval sram_config_extra_size 1   // adjust and renumber config options as more are added
// Mode IDs (specific to this hack)
eval mode_id_anypercent 0  // Any%, which just means Zero isn't saved.
// Route IDs
eval route_id_stag3rd 0    // Route where Flame Stag is killed 3rd.
// Level IDs
eval level_id_intro 0
eval level_id_moth 1
eval level_id_sponge 2
eval level_id_crab 3
eval level_id_stag 4
eval level_id_centipede 5
eval level_id_snail 6
eval level_id_ostrich 7
eval level_id_gator 8
eval level_id_violen 9
eval level_id_serges 10
eval level_id_agile 11
eval level_id_teleporter 12
eval level_id_sigma 13  // fake
// Other constants
eval play_state_normal $04
eval play_state_death $06
eval select_button $2000
eval stage_select_id_hunter $FF
eval stage_select_id_x $80
eval unknown_level_flag_value_normal $01
eval unknown_level_flag_value_xhunter $FF
eval magic_sram_tag_lo $454D  // Combined, these say "MEOW"
eval magic_sram_tag_hi $574F

{savepc}
	// Change SRAM size to 256 KB
	{reorg $00FFD8}
	db $08
{loadpc}

{savepc}
	{reorg $00800E}
	jml init_hook
{loadpc}

{savepc}
	{reorg $00C622}
	// Always allow exiting levels
patch_exit_hack:
	lda.b #$40
	rts
{loadpc}


{savepc}
	{reorg $00BF96}
	// Jump to choose_level_hook
patch_choose_level_hook:
	jml choose_level_hook
{loadpc}


{savepc}
	{reorg $00BD29}
	// Don't play the Counter-Hunter stage select music.  It's annoying.
	// The above patch causes it to always play otherwise.
patch_dont_play_counter_hunter_music:
	ora.b #0
{loadpc}


{savepc}
	{reorg $0096D4}
patch_skip_intro:
	// Skip the intro.  If they want to play the intro, they can select the
	// Maverick icon at stage select (what would normally be the Counter-
	// Hunter choice).
	bra $0096F2
{loadpc}


{savepc}
	{reorg $00BD25}
	// When loading stage select, always reset to a default state with all
	// bosses undefeated, so that they all appear available.
	// Yes, this patch is immediately before the Counter-Hunter music one.
patch_stage_select_reset_state:
	jsl stage_select_reset_state
{loadpc}


{savepc}
	{reorg $0099AD}
	// Infinite lives.  Don't decrement the life counter, and don't do
	// anything if you die with zero lives.
patch_infinite_lives:
	bra $0099B2
{loadpc}


{savepc}
	// These prevent the teleporters in the "boss repeat"/"teleporter" stage
	// from disabling themselves after beating a boss.  This allows the runner
	// to repeat the boss as much as she wants.
	// Unfortunately, each boss has their own assembly code to patch.
	//
	// Morph Moth
	{reorg $298D99}
	nop  // NOP's TSB of $01 into $7E1FD9
	nop
	nop
	// Wire Sponge
	{reorg $04A752}
	nop  // NOP's TSB of $02 into $7E1FD9
	nop
	nop
	// Bubble Crab
	{reorg $07CA69}
	nop  // NOP's TSB of $04 into $7E1FD9
	nop
	nop
	// Flame Stag
	{reorg $04C2F1}
	nop  // NOP's TSB of $08 into $7E1FD9
	nop
	nop
	// Magna Centipede
	{reorg $04B1F3}
	nop  // NOP's TSB of $10 into $7E1FD9
	nop
	nop
	// Crystal Snail
	{reorg $07BD6B}
	nop  // NOP's TSB of $20 into $7E1FD9
	nop
	nop
	// Overdrive Ostrich
	{reorg $08F0AE}
	nop  // NOP's TSB of $40 into $7E1FD9
	nop
	nop
	// Wheel Gator
	{reorg $03BFDF}
	nop  // NOP's TSB of $80 into $7E1FD9
	nop
	nop
{loadpc}


{savepc}
	{reorg $009A6A}
	// Skip cutscenes:
	// - X-Hunters after intro
	// - X-Hunters after 2 mavericks
	// - Dr. Cain after 8 mavericks
	// - Ending
	bra $009A9C
{loadpc}


{savepc}
	{reorg $009715}
	// Disable the stage intros for the 8 mavericks.
patch_disable_stage_intros:
	bra $009708
{loadpc}

// Disable interstage password screen.
{savepc}
	// Always use password screen state 3, which is used to exit to stage select.
	// States are offsets into a jump table, so they're multiplied by 2.
	{reorg $00EF49}
	ldx.b #3 * 2
	// Disable fadeout, speeding this up.
	{reorg $00EFFE}
	nop
	nop
	nop
{loadpc}

{savepc}
	{reorg $03F2E6}
	// Disable the "TV screen" flashing effect on stage select.
patch_disable_flashy_effect:
	// $7E1F53 contains a counter that goes 012012012012... and overlays the
	// annoying effect when it is zero.  Just force it to 1.
	lda.b #1
	bra $03F2ED
{loadpc}


{savepc}
	// Make the scrolling to the Counter-Hunters' island instant.
	// The "PEA" is to trick the "RTS" at $2AAE7A and $2AAEAD into jumping
	// to $2AAECE afterward, fixing the palette.
patch_disable_scroll_up:
	{reorg $2AAE62}
	lda.w #$0100
	sta.b $08
	pea ($2AAECE - 1) & $00FFFF
	bra $2AAE72
patch_disable_scroll_down:
	{reorg $2AAE91}
	lda.w #$0200
	sta.b $08
	pea ($2AAECE - 1) & $00FFFF
	bra $2AAEA1
{loadpc}


{savepc}
	{reorg $08BF41}
	// Allow pressing select + start to simulate death.
	// This hook activates when the game is checking to see whether the
	// player is pressing L or R to change weapons.
patch_death_command_hook:
	jml death_command_hook
{loadpc}

{savepc}
	{reorg $0090E2}
	// Change where Rockman starts on the title screen, which is hardcoded.
patch_title_rockman_default_location:
	lda.b #$96
{loadpc}


{savepc}
	// Make the number of title screen options 4 instead of 3.
	{reorg $00915F}
patch_title_num_options_up:
	lda.b #3
	{reorg $00916A}
patch_title_num_options_down:
	cmp.b #4
{loadpc}


{savepc}
	// Make the jump table for four options work correctly.
	// We delete the Password option, and the first three options all start
	// the game.  We simply read out title_screen_option later to distinguish
	// among those.  So a simple compare will suffice here!
	{reorg $0091FF}
patch_title_option_jump_table:
	cmp.b #3
	beq $00923A
	bra $00920A
{loadpc}


{savepc}
	{reorg $009173}
	// Call our routine when the title screen cursor moves.
patch_title_cursor_moved:
	jml title_cursor_moved
{loadpc}


{savepc}
	// 2 KB available here.
	{reorg $03F800}

choose_level_hook:
	// Entering with 8-bit A, unknown-size X/Y
	phx
	phy
	php
	phb
	rep #$10

	// Remap choice into route_table index (value 0-9, doubled to 0-19 based
	// on whether select is held).

	// First check for special options (X, counter-hunter)
	cmp.b #{stage_select_id_hunter}
	beq .hunter_level
	ora.b #0
	bmi .x_icon

	// For the normal cases, look the index into the route table.
	xba
	lda.b #0
	xba
	tax
	lda.l level_id_to_route_table_map, x
	bra .select_check

.hunter_level:
	lda.b #8
	bra .select_check
.x_icon:
	lda.b #3
	// Fall through to .select_check.

.select_check:
	// Holding the select button?
	pha
	lda.w {controller_1_current} + 1
	and.b #{select_button} >> 8
	beq .do_route_lookup

	// If so, add 10 to the index into the route table.
	pla
	clc
	adc.b #10
	pha

.do_route_lookup:
	// Switch to 16-bit and re-save the level as 16-bit, this time in Y.
	pla
	rep #$20
	and.w #$00FF
	tay

	// Look up the pointer to the route table for the current mode.
	// The title screen option is left alone from back then.
	lda.w {title_screen_option}
	and.w #$00FF
	asl
	tax
	lda.l route_metatable, x

	// I need a temporary variable in memory for the add, and I can't find
	// one, so I just overwrite something I see used recently and save it to
	// the stack.  >.<
	ldx.b $29
	phx
	sta.b $29

	// Look up the route data pointer for the chosen level from that table.
	tya
	asl  // Clears carry because the value is small.
	adc.b $29

	// Restore unknown destroyed variable before continuing.
	ply
	sty.b $29

	tax
	// The table is offset by 1, so the + 2 that'd be needed to skip over the
	// table's entry for stage select itself is nullified by being offset.
	lda.l (route_table_bank_marker & $FF0000) + 2 - 2, x

	// If the value is 0, treat it as the X option.
	beq .x_option

	// Copy the state data into place.  MVN changes the bank register, but it
	// doesn't affect anything we're up to.
	tax
	lda.w #64 - 1
	ldy.w #{state_vars}
	mvn {state_vars} >> 16 = state_data_bank_marker >> 16

	// Read back the level ID.  The bank MVN set is compatible with this.
	sep #$20
	lda.w {current_level}

	// We need to set an unknown flag based on whether a stage is a Counter-
	// Hunter level.  This is easy for the first four levels; just check the
	// final level ID for being 9 or greater.  The fifth level, however, is
	// just Magna Centipede's, so we have to be a bit more creative.  We check
	// how many Counter Hunter levels you've beaten.  If you're on Magna
	// Centipede's level and have beaten 4 Counter-Hunter levels, you're in a
	// Counter-Hunter level.  (The game doesn't care which you chose.)
	cmp.b #9
	bcs .loading_hunter_level
	cmp.b #5
	bne .loading_normal_level
	lda.w {xhunter_level}
	cmp.b #4
	bcc .loading_normal_level

.loading_hunter_level:
	lda.b #{unknown_level_flag_value_xhunter}
	bra .loading_level

.loading_normal_level:
	lda.b #{unknown_level_flag_value_normal}

.loading_level:
	sta.w {unknown_level_flag}
	plb
	plp
	ply
	plx
	jml $00BFC9

.x_option:
	// A is still 16-bit, but we do a PLP here.
	plb
	plp
	ply
	plx
	jml $00BFA6


// The player is moving the cursor on the title screen.  First things
// first: we now have a 4-element table instead of a 3-element table,
// so we have to move the table order to expand it.  As is typical, it's
// in bank 6, but it's only 4 bytes.
title_cursor_moved:
	lda.l title_rockman_location, x
	sta.w $7E09E0

	// Draw the currently-highlighted string.
	lda.b #$10  // Is this store required?
	sta.b $02

	lda.w {title_screen_option}
	rep #$20
	and.w #$00FF
	asl
	tax
	lda.l title_screen_string_table, x
	sta.b $10
	sep #$20

	// Engineer a near return to $009181.
	pea ($009181 - 1) & $FFFF
	// Jump to the middle of draw_string.
	jml $00867B


// Called when stage select is first loaded.  Reset the state to all bosses
// undefeated for display purposes.  We'll load a better state when a stage
// is selected.  This also means that we don't need to load a route-specific
// state here, so just always use Any% Stag 3rd.
stage_select_reset_state:
	// The original function destroys A and X, and sets A and X to 8-bit, so I
	// don't have to be too careful here.  I'm going to assume Y isn't needed.
	rep #$30

	phb  // MVN modifies the bank register
	lda.w #64 - 1
	ldx.w #state_data_anypercent.intro
	ldy.w #{state_vars}
	mvn {state_vars} >> 16 = state_data_bank_marker >> 16
	plb

	// Always show the Counter-Hunter option, which is our intro stage.  We do
	// this by writing 8 (number of dead bosses) to this variable, whatever it
	// is, and by setting the zero flag before returning.
	sep #$30  // original function set X and Y to 8-bit as well.
	lda.b #8
	sta.b $2C
	cmp.b #8
	rtl


// Called when the game is checking for L/R for changing weapons.
// Select+Start is a request to kill Rockman X, in order to restart.
// I hook this particular location because it more or less guarantees that the
// game engine is in a state in which I can do this.
death_command_hook:
	// Entering with 8-bit A and 8-bit X.

	// Check for Select + Start.
	lda.w {controller_1_current} + 1
	and.b #$30
	cmp.b #$30
	bne .original_code

	// Check for being in the normal state, so as to not activate this code
	// unless we're in the expected state.
	lda.w {current_play_state}
	cmp.b #{play_state_normal}
	bne .original_code

	// OK, kill him.  The countdown $01 fades out immediately.  $F0 is the
	// normal countdown for death.
	lda.b #{play_state_death}
	sta.w {current_play_state}
	lda.b #$01
	sta.w {countdown_play_state}

	// Jump back to an RTS.  If neither L nor R is being pressed, the game
	// branches to this RTS, so this is the right place to go.  Labeled
	// "not_pressing_R" in sub_8BECC in my disassembly.
.jump_to_rts:
	bra .not_pressing_R  // save 2 bytes by jumping to other jml

.original_code:
	// The replaced code checks for R being pressed, so we copy that here.
	// We need to reload A from D+$3A, though, because we destroyed it above.
	lda.b $3A
	bit.b #$10
	beq .not_pressing_R
	jml $08BF45
.not_pressing_R:
	jml $08BFAC


// Use this label >> 16 as the bank for the following route and mode tables.
route_table_bank_marker:

level_id_to_route_table_map:
	db $FF, 2, 1, 7, 4, 5, 10, 6, 9

route_table_anypercent:
	// For stage select
	dw state_data_anypercent.sponge
	// Without select button
	dw state_data_anypercent.sponge
	dw state_data_anypercent.moth
	dw 0  // placeholder for the X
	dw state_data_anypercent.stag
	dw state_data_anypercent.centipede
	dw state_data_anypercent.ostrich
	dw state_data_anypercent.crab
	dw state_data_anypercent.intro
	dw state_data_anypercent.gator
	dw state_data_anypercent.snail
	// With select button
	dw state_data_anypercent.violen               // \   These ones are replaced
	dw state_data_anypercent.serges               //  \  versus normal.
	dw state_data_anypercent.agile                //   > X becomes Agile.
	dw state_data_anypercent.teleporter           //  /
	dw state_data_anypercent.sigma                // /
	dw state_data_anypercent.ostrich
	dw state_data_anypercent.crab
	dw state_data_anypercent.intro
	dw state_data_anypercent.gator
	dw state_data_anypercent.snail

route_table_100percent:
	// For stage select
	dw state_data_100percent.sponge
	// Without select button
	dw state_data_100percent.sponge
	dw state_data_100percent.moth
	dw 0  // placeholder for the X
	dw state_data_100percent.stag
	dw state_data_100percent.centipede
	dw state_data_100percent.ostrich
	dw state_data_100percent.crab
	dw state_data_100percent.intro
	dw state_data_100percent.gator
	dw state_data_100percent.snail
	// With select button
	dw state_data_100percent.violen            // \   These ones are replaced
	dw state_data_100percent.serges            //  \  versus normal.
	dw state_data_100percent.agile             //   > X becomes Agile.
	dw state_data_100percent.teleporter        //  /
	dw state_data_100percent.sigma             // /
	dw state_data_100percent.ostrich
	dw state_data_100percent.crab
	dw state_data_100percent.intro
	dw state_data_100percent.gator
	dw state_data_100percent.snail

route_table_lowpercent:
	// For stage select
	dw state_data_lowpercent.sponge
	// Without select button
	dw state_data_lowpercent.sponge
	dw state_data_lowpercent.moth
	dw 0  // placeholder for the X
	dw state_data_lowpercent.stag
	dw state_data_lowpercent.centipede
	dw state_data_lowpercent.ostrich
	dw state_data_lowpercent.crab
	dw state_data_lowpercent.intro
	dw state_data_lowpercent.gator
	dw state_data_lowpercent.snail
	// With select button
	dw state_data_lowpercent.violen                       // \   These ones are replaced
	dw state_data_lowpercent.serges                       //  \  versus normal.
	dw state_data_lowpercent.agile                        //   > X becomes Agile.
	dw state_data_lowpercent.teleporter                   //  /
	dw state_data_lowpercent.sigma                        // /
	dw state_data_lowpercent.ostrich
	dw state_data_lowpercent.crab
	dw state_data_lowpercent.intro
	dw state_data_lowpercent.gator
	dw state_data_lowpercent.snail


route_metatable:
	dw route_table_anypercent
	dw route_table_100percent
	dw route_table_lowpercent


{loadpc}

// Macros for creating new strings.
macro option_string label, string, vramaddr, attribute, terminator
	{label}:
		db {label}_end - {label}_begin, {attribute}
		dw {vramaddr} >> 1
	{label}_begin:
		db {string}
	{label}_end:
	if {terminator}
		db 0
	endif
endmacro

macro option_string_pair label, string, vramaddr
	{option_string {label}_normal, {string}, {vramaddr}, $20, 1}
	{option_string {label}_highlighted, {string}, {vramaddr}, $28, 1}
endmacro

//640 bytes available
{reorg $86FD80}

initial_menu_strings:
	// I'm too lazy to rework the compressed font, so I use this to overwrite
	// the ` character in VRAM.  The field used for the "attribute" of the
	// "text" just becomes the high byte of each pair of bytes.
	macro tilerow vrambase, rownum, col7, col6, col5, col4, col3, col2, col1, col0
		db 1, (({col7} & 2) << 6) | (({col6} & 2) << 5) | (({col5} & 2) << 4) | (({col4} & 2) << 3) | (({col3} & 2) << 2) | (({col2} & 2) << 1) | ({col1} & 2) | (({col0} & 2) >> 1)
		dw (({vrambase}) + (({rownum}) * 2)) >> 1
		db (({col7} & 1) << 7) | (({col6} & 1) << 6) | (({col5} & 1) << 5) | (({col4} & 1) << 4) | (({col3} & 1) << 3) | (({col2} & 1) << 2) | (({col1} & 1) << 1) | ({col0} & 1)
	endmacro

	macro optionset label, attrib1, attrib2, attrib3, attrib4
		{option_string .option1_{label}, "ANY`", $1492, {attrib1}, 0}
		{option_string .option2_{label}, "100`", $1512, {attrib2}, 0}
		{option_string .option3_{label}, "LOW`", $1592, {attrib3}, 0}
		{option_string .option4_{label}, "OPTIONS", $1612, {attrib4}, 1}
	endmacro

	{tilerow $0600, 0,   0,2,3,0,0,0,2,3}
	{tilerow $0600, 1,   2,3,2,3,0,2,3,0}
	{tilerow $0600, 2,   3,1,3,0,1,3,0,0}
	{tilerow $0600, 3,   0,3,0,1,3,0,0,0}
	{tilerow $0600, 4,   0,0,1,3,0,1,3,0}
	{tilerow $0600, 5,   0,2,3,0,2,3,2,3}
	{tilerow $0600, 6,   2,3,0,0,3,2,3,0}
	{tilerow $0600, 7,   3,0,0,0,0,3,0,0}

	// Menu text.  I've added an extra option versus the original and moved it
	// one tile to the left for better centering.  I also added the edition
	// text to the top.
	{option_string .edition, "- Practice Edition -", $138E, $28, 0}

// Option set 1 can be overlapped with the tail of initial_menu_strings.
option_set_1:
	{optionset s1, $24, $20, $20, $20}
	db 0
option_set_2:
	{optionset s2, $20, $24, $20, $20}
	db 0
option_set_3:
	{optionset s3, $20, $20, $24, $20}
	db 0
option_set_4:
	{optionset s4, $20, $20, $20, $24}
	db 0

// Replacement copyright string.  @ in the X2 font is the copyright symbol.
copyright_string:
	{option_string .rockman_x2, "ROCKMAN X2", $1256, $20, 0}
	// The original drew a space then went back and drew a copyright symbol
	// over the space.  I don't see a need to do that - I'll draw a copyright
	// symbol in the first place.
	{option_string .capcom, "@ CAPCOM CO.,LTD.1994", $128C, $20, 0}
	// My custom message.  The opening quotation mark is flipped.
	// Don't use the macro for this text due to technical limitations.
	db 1, $60
	dw $138E >> 1
	db '"'
	db .practice_end - .practice_start, $20
	dw $1390 >> 1
.practice_start:
	db "PRACTICE EDITION",'"'
.practice_end:
	{option_string .credit, "BY MYRIA, TOTAL,                  AND AKITERU", $1453, $20, 0}
	// Don't use the macro for this text due to technical limitations.
	db .version_end - .version_start, $20
	dw $14CF >> 1
.version_start:
	db "2014-2020 Ver. "
	db $30 + {version_major}, '.', $30 + {version_minor}, $30 + {version_revision}
.version_end:
	// Terminates sequence of VRAM strings.
	db 0

// Extra strings added to the table.
{option_string_pair string_keeprng, "KEEP RNG", $158E}
{option_string string_keeprng_on, "ON ", $15A8, $34, 1}
{option_string string_keeprng_off, "OFF", $15A8, $34, 1}

{savepc}
	// Overwrite the copyright string pointer.
	{reorg $068C7B}
	dw copyright_string

	// Overwrite the title screen string pointers with this one.
	{reorg $068C8F}
	dw initial_menu_strings
	dw initial_menu_strings
	dw initial_menu_strings
{loadpc}

// New additions to string table.  This table has reserved entries not being used.
{savepc}
	{reorg {rom_bank84_string_table}}
string_table:
	macro stringtableentry label
		.idcalc_{label}:
			dw (string_{label}) & $FFFF
		eval stringid_{label} ((string_table.idcalc_{label} - string_table) / 2) + {num_used_string_table}
	endmacro

	{stringtableentry keeprng_normal}
	{stringtableentry keeprng_highlighted}
	{stringtableentry keeprng_off}
	{stringtableentry keeprng_on}
{loadpc}

// Hack initial config menu routine to add more strings.
{savepc}
	{reorg $80EA70}
	jml config_menu_start_hook
{loadpc}
config_menu_start_hook:
	// We enter with A/X/Y 8-bit and bank set to $86 (our code bank)
	// Deleted code.  We need to do this first, or 815F fails.
	lda.b #7
	tsb.w $7E00A3

	ldx.b #0
.string_loop:
	lda.w config_menu_extra_string_table, x
	phx
	beq .string_flush
	cmp.b #$FF
	beq .special
	jsl trampoline_808669
	bra .string_next
.special:
	// Call a function
	inx
	clc   // having carry clear is convenient for these functions
	jsr (config_menu_extra_string_table, x)
	jsl trampoline_808669
	plx
	inx
	inx
	bra .special_resume
.string_flush:
	jsl trampoline_80815F
.string_next:
	plx
.special_resume:  // save 1 byte by using the extra inx here
	inx
	cpx.b #config_menu_extra_string_table.end - config_menu_extra_string_table
	bne .string_loop
	jml $80EA75

// Table of static strings to render at config screen load time.
config_menu_extra_string_table:
	// Extra call to 815F to execute and flush the draw buffer before our first
	// string, otherwise we end up drawing too much.
	db $00
	// Selectable option labels.
	db {stringid_keeprng_normal}
	//db $00  // flush
	// Extra option values.
	db $FF
	dw config_get_stringid_keeprng
	db $00  // flush
	db $27  // EXIT
	// We return to a flush call.
.end:

config_get_stringid_keeprng:
	lda.l {sram_config_keeprng}
	and.b #$01
	adc.b #{stringid_keeprng_off}
	rts

// Trampoline for calling $80815F  (flush string draw buffer?)
trampoline_80815F:
	pea ({rom_rtl_instruction} - 1) & 0xFFFF
	jml $80815F
// Trampoline for calling $808669  (draw string)
trampoline_808669:
	pea ({rom_rtl_instruction} - 1) & 0xFFFF
	jml $808669

config_option_jump_table:
	// These are minus one due to using RTL to jump to them.
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_button} - 1
	dl {rom_config_stereo} - 1
	//dl config_code_keeprng - 1
	dl {rom_config_exit} - 1

{savepc}
	// Use our alternate table.
	//DP = 06 here, which is why config_unhighlighted_string_ids is in bank 86 (mirror)
	{reorg $80EB18}
	lda.w config_unhighlighted_string_ids,x
	{reorg $80EB35}
	lda.w config_unhighlighted_string_ids,x
{loadpc}
config_unhighlighted_string_ids:
	db $23 // SHOT
	db $25 // JUMP
	db $27 // DASH
	db $29 // SELECT_L
	db $2B // SELECT_R
	db $2D // MENU
	db $2F // STEREO/MONO
	//db {stringid_keeprng_normal}
	db $2F // EXIT?? Not sure why this isn't different to stereo/mono.

{savepc}
	// Option Mode position hacks

	// Do not draw borders, only draw highlighted menu headers, move SOUND MODE up
	{reorg $869038}
	{option_string .key_config_normal, "KEY CONFIG", $11D6, $34, 1}
	{reorg $86905B}
	db $00 // Terminating the string sections immediately with these
	{reorg $8690AC}
	db $00
	{reorg $8690CB}
	{option_string .key_config_highlighted, "KEY CONFIG", $11D6, $34, 1}
	{reorg $8690EE}
	db $00
	{reorg $86913F}
	db $00
	{reorg $86915E}
	{option_string .sound_mode_normal, "SOUND MODE", $1417, $34, 0}
	{option_string .misc_normal, "MISC", $151C, $34, 1}
	{reorg $869181}
	db $00
	{reorg $8691A0}
	db $00
	{reorg $8691BF}
	{option_string .sound_mode_highlighted, "SOUND MODE", $1417, $34, 0}
	{option_string .misc_highlighted, "MISC", $151C, $34, 1}
	{reorg $8691E2}
	db $00
	{reorg $869201}
	db $00

	//Move STEREO/MONAURAL and EXIT up
	// Stereo/Mono
	{reorg $8692B0}
	dw $1498 >> 1
	{reorg $8692BD}
	dw $1498 >> 1
	{reorg $8692CA}
	dw $1498 >> 1
	{reorg $8692D7}
	dw $1498 >> 1

	// Exit
	{reorg $86929E}
	dw $165C >>1
	{reorg $8692A7}
	dw $165C >>1
{loadpc}

// 297 bytes available here. Mirrors $007E77 in the ROM.
{reorg $80FE77}

{savepc}
	// Use config_option_jump_table instead of the built-in one.
	// Note that we can overwrite the config table.
	{reorg $80EB59}
	// clc not necessary because of asl of small value
	adc.l {config_selected_option}
	tax
	lda.l config_option_jump_table + 2, x
	pha
	rep #$20
	lda.l config_option_jump_table + 0, x
	pha
	sep #$20
	rtl
{loadpc}

// Hack draw_string to use our custom table.
{savepc}
	{reorg $808669}
	jmp draw_string_hack
{loadpc}
draw_string_hack:
	// This assumes that we stay in bank 80.
	// Overwritten code
	sep #$30
	sta.b $02
	and.b #$7F    // might change this if we need more than 127 strings
	asl
	tay
	// Is this one of our extra strings?
	cpy.b #{num_used_string_table} * 2
	bcc .old_table
	// Switch to the other bank.
	phb
	pea ({rom_bank84_string_table} >> 16) * $0101
	plb
	plb
	// Refer to the new table instead.
	lda {rom_bank84_string_table} - ({num_used_string_table} * 2), y
	sta.b $10
	lda {rom_bank84_string_table} - ({num_used_string_table} * 2) + 1, y
	sta.b $11
	// Return to original code.
	plb
	jmp $80867B
.old_table:
	// Use the original code.
	jmp $808671 + 0 // The "+ 0" was necessary to compile for some reason. bass bug?


{savepc}
	// 4 KB available here.
	{reorg $04F000}
// Use this label >> 16 as the bank for state data blocks.
state_data_bank_marker:

// State data for Any%
state_data_anypercent:
.intro:
	//  0. Intro stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $00,$10,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.sponge:
	//  1. Wire Sponge's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$40
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $00,$10,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.gator:
	//  2. Wheel Gator's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $40,$12,$01,$80,$00,$48,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.stag:
	//  3. Flame Stag's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $42,$14,$01,$A0,$00,$1B,$01,$04,$07,$00,$00,$00,$00,$00,$00,$58
.centipede:
	//  4. Magna Centipede's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$DC,$00,$00,$00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$DC
	db $62,$16,$01,$A2,$00,$24,$03,$00,$01,$00,$00,$00,$00,$00,$00,$58
.snail:
	//  5. Crystal Snail's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$8E,$00,$00,$00,$00,$00,$00,$00
	db $00,$DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$DC
	db $72,$18,$01,$AA,$00,$51,$06,$00,$03,$00,$00,$00,$00,$00,$00,$58
.ostrich:
	//  6. Overdrive Ostrich's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$8E,$00,$00,$DC,$00,$00,$00,$00
	db $00,$DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$DC,$00,$DC
	db $73,$1A,$01,$BA,$00,$2D,$00,$00,$07,$00,$00,$00,$00,$00,$00,$58
.crab:
	//  7. Bubble Crab's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$8E,$00,$00,$DC,$00,$00,$00,$00
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$DC,$00,$DC
	db $7B,$1C,$01,$BE,$00,$36,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.moth:
	//  8. Morph Moth's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$00
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$DC,$00,$DC
	db $FB,$1E,$01,$FE,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.violen:
	//  9. Violen's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$00,$E0
	db $00,$00,$00,$03,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.serges:
	// 10. Serges's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$01,$E0
	db $00,$00,$00,$03,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$5C,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.agile:
	// 11. Agile's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$02,$E0
	db $00,$00,$00,$03,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$5C,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.teleporter:
	// 12. Boss Repeats ("Teleporter" stage)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$03,$E0
	db $00,$80,$00,$04,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$5C,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.sigma:
	// 13. Sigma (Magna Centipede redux)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$04,$E0
	db $00,$80,$00,$04,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$5C,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$58

// State data for 100%
state_data_100percent:
.intro:
	//  0. Intro stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $00,$10,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.sponge:
	//  1. Wire Sponge's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$40
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $00,$10,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.gator:
	//  2. Wheel Gator's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $40,$12,$01,$80,$00,$48,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.stag:
	//  3. Flame Stag's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $42,$14,$01,$A0,$00,$2D,$01,$04,$07,$00,$00,$00,$00,$00,$00,$58
.ostrich:
	//  4. Overdrive Ostrich's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$DC,$00,$00,$00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00
	db $62,$16,$40,$A2,$00,$2D,$03,$80,$01,$00,$00,$00,$00,$00,$00,$58
.crab:
	//  5. Bubble Crab's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00
	db $6A,$18,$40,$A6,$00,$36,$05,$80,$03,$00,$00,$00,$00,$00,$00,$58
.centipede:
	//  6. Magna Centipede's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$8E,$00,$00,$00,$00,$DC,$00,$00
	db $00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00
	db $EA,$1A,$40,$E6,$00,$24,$06,$80,$80,$00,$00,$00,$00,$00,$00,$58
.snail:
	//  7. Crystal Snail's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$8E,$8E,$00,$00,$00,$DC,$00,$00
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $FA,$1C,$40,$EE,$00,$51,$01,$80,$80,$00,$00,$00,$00,$00,$00,$58
.moth:
	//  8. Morph Moth's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$40
	db $00,$00,$00,$02,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$00
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$DC,$00,$00
	db $FB,$1E,$40,$FE,$00,$09,$01,$80,$80,$00,$00,$00,$00,$00,$00,$58
.violen:
	//  9. Violen's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$00,$E0
	db $00,$00,$00,$03,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$80,$4D,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$80,$80,$80,$00,$00,$00,$00,$00,$00,$58
.serges:
	// 10. Serges's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$01,$E0
	db $00,$00,$00,$03,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$80,$55,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$80,$80,$80,$00,$00,$00,$00,$00,$00,$58
.agile:
	// 11. Agile's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$02,$E0
	db $00,$00,$00,$03,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$80,$80,$80,$00,$00,$00,$00,$00,$00,$58
.teleporter:
	// 12. Boss Repeats ("Teleporter" stage)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$03,$E0
	db $00,$80,$00,$03,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$5C,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$80,$80,$80,$00,$00,$00,$00,$00,$00,$58
.sigma:
	// 13. Sigma (Magna Centipede redux)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$04,$E0
	db $00,$80,$00,$03,$00,$01,$8E,$8E,$8E,$8E,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$5C,$00,$DC,$00,$DC
	db $FF,$20,$01,$FF,$01,$3F,$80,$80,$80,$FF,$00,$00,$00,$00,$00,$58

// State data for Low%
state_data_lowpercent:
.intro:
	//  0. Intro stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $00,$10,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.sponge:
	//  1. Wire Sponge's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$40
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $00,$10,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.gator:
	//  2. Wheel Gator's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$00,$48,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.stag:
	//  3. Flame Stag's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$00,$1B,$01,$04,$07,$00,$00,$00,$00,$00,$00,$58
.moth:
	//  4. Morph Moth's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$DC,$00,$00,$00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.centipede:
	//  5. Magna Centipede's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $00,$DC,$00,$00,$00,$DC,$00,$00,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$00,$24,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.snail:
	//  6. Crystal Snail's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$DC
	db $00,$DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$00,$51,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.ostrich:
	//  7. Overdrive Ostrich's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$DC
	db $00,$DC,$00,$00,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$00,$2D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.crab:
	//  8. Bubble Crab's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$40
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$00,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$00,$36,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.violen:
	//  9. Violen's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$00,$E0
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$01,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.serges:
	// 10. Serges's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$01,$E0
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$01,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.agile:
	// 11. Agile's stage
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$02,$E0
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$01,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.teleporter:
	// 12. Boss Repeats ("Teleporter" stage)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$03,$E0
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$01,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58
.sigma:
	// 13. Sigma (Magna Centipede redux)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$04,$E0
	db $00,$00,$00,$02,$00,$01,$00,$00,$00,$00,$00,$DC,$00,$DC,$00,$DC
	db $00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$DC,$00,$00,$00,$00,$00,$00
	db $00,$10,$40,$00,$01,$24,$00,$00,$00,$00,$00,$00,$00,$00,$00,$58


// Unrelated stuff moved here.

// Pointers to the option strings.
title_screen_string_table:
	dw option_set_1
	dw option_set_2
	dw option_set_3
	dw option_set_4

// Y coordinates of Rockman corresponding to each option.
title_rockman_location:
	db $96, $A6, $B6, $C6

{loadpc}

{savepc}
	{reorg $0885A4}
nmi_patch:
	// We use controller 2's state, which is ignored by the game unless debug
	// modes are enabled (which we don't do).  Controller 2 state is the state
	// of the "real" controller.  When the game disables the controller, we
	// simply don't copy controller 2 to controller 1.

	// Move previous frame's controller data to the previous field.
	lda.b {controller_2_current}
	sta.b {controller_2_previous}

	// Read controller 1 port.  This is optimized from the original slightly.
	lda.w $4218
	bit.w #$000F
	beq .controller_valid
	lda.w #0
.controller_valid:

	// Update controller 2 variables, which is where we store the actual
	// controller state.
	sta.b {controller_2_current}
	eor.b {controller_2_previous}
	and.b {controller_2_current}
	sta.b {controller_2_new}

	// If controller is enabled, copy 2's state to 1's state.
	lda.w {controller_1_disable}
	and.w #$00FF
	bne .controller_disabled
	lda.b {controller_2_current}
	sta.b {controller_1_current}
	lda.b {controller_2_previous}
	sta.b {controller_1_previous}
	lda.b {controller_2_new}
	sta.b {controller_1_new}
.controller_disabled:
	// Check for Select being held.  Jump to nmi_hook if so.
	lda.b {controller_2_current}
	bit.w #$2000
	beq .resume_nmi
	jml nmi_hook
.resume_nmi:
	rts
	// I don't think this version of bass has warnpc, but there's apparently only 3 bytes left here (from X3 hack)
	//{warnpc {rom_nmi_after_controller}}
{loadpc}


{savepc}
	// Saved state hacks
	{reorg $03FA00}

init_hook:
	// Deleted code.
	sta.l $7EFFFF
	// What we need to do at startup.
	sta.l {sram_previous_command}
	sta.l {sram_previous_command}+1
	// Return to original code.
	jml $008012

// Called during NMI if select is being held.
nmi_hook:
	// Check for L or R newly being pressed.
	lda.b {controller_2_new}
	and.w #$0030

	// We now can execute slow code, because we know that the player is giving
	// us a command to do.

	// This is a command to us, so we want to hide the button press from the game.
	tax
	lda.w #$FFCF
	and.b {controller_2_current}
	sta.b {controller_2_current}
	lda.w #$FFCF
	and.b {controller_2_new}
	sta.b {controller_2_new}

	// If controller data is enabled, copy these new fields, too.
	lda.w {controller_1_disable}
	and.w #$00FF
	bne .controller_disabled
	lda.b {controller_2_current}
	sta.b {controller_1_current}
	lda.b {controller_2_new}
	sta.b {controller_1_new}
.controller_disabled:
	txa

	// We need to suppress repeating ourselves when L or R is held down.
	cmp.l {sram_previous_command}
	beq .return_normal_no_rep
	sta.l {sram_previous_command}

	// Distinguish between the cases.
	cmp.w #$0010
	beq .select_r
	cmp.w #$0020
	bne .return_normal_no_rep
	jmp .select_l

// Resume NMI handler, skipping the register pushes.
.return_normal:
	rep #$38
.return_normal_no_rep:
	jml {ram_nmi_after_controller}

// Play an error sound effect.
.error_sound_return:
	// Clear the bank register, because we don't know how it was set.
	pea $0000
	plb
	plb

	sep #$20
	lda.b #$5A
	jsl {rom_play_sound}
	bra .return_normal

// Select and R pushed = save.
.select_r:
	// Clear the bank register, because we don't know how it was set.
	pea $0000
	plb
	plb

	// Mark SRAM's contents as invalid.
	lda.w #$1234
	sta.l {sram_validity} + 0
	sta.l {sram_validity} + 2

	// Test SRAM to verify that 256 KB is present.  Protects against bad
	// behavior on emulators and Super UFO.
	sep #$10
	lda.w #$1234
	ldy.b #{sram_start} >> 16

	// Note that we can't do a write-read-write-read pattern due to potential
	// "open bus" issues, and because mirroring is also possible.
	// Essentially, this code verifies that all 8 banks are storing
	// different data simultaneously.
.sram_test_write_loop:
	phy
	plb
	sta.w $0000
	inc
	iny
	cpy.b #(({sram_start} >> 16) + {sram_banks})
	bne .sram_test_write_loop

	// Read the data back and verify it.
	lda.w #$1234
	ldy.b #{sram_start} >> 16
.sram_test_read_loop:
	phy
	plb
	cmp.w $0000
	bne .error_sound_return
	inc
	iny
	cpy.b #(({sram_start} >> 16) + {sram_banks})
	bne .sram_test_read_loop


	// Mark the save as invalid in case we lose power or crash while saving.
	rep #$30
	lda.w #0
	sta.l {sram_validity}
	sta.l {sram_validity} + 2

	// Store DMA registers' values to SRAM.
	ldy.w #0
	phy
	plb
	plb
	tyx

	sep #$20
.save_dma_reg_loop:
	lda.w $4300, x
	sta.l {sram_dma_bank}, x
	inx
	iny
	cpy.w #$000B
	bne .save_dma_reg_loop
	cpx.w #$007B
	beq .save_dma_regs_done
	inx
	inx
	inx
	inx
	inx
	ldy.w #0
	jmp .save_dma_reg_loop
	// End of DMA registers to SRAM.

.save_dma_regs_done:
	// Run the "VM" to do a series of PPU writes.
	rep #$30

	// X = address in this bank to load from.
	// B = bank to read from and write to
	ldx.w #.save_write_table
.run_vm:
	pea (.vm >> 16) * $0101
	plb
	plb
	jmp .vm

// List of addresses to write to do the DMAs.
// First word is address; second is value.  $1000 and $8000 are flags.
// $1000 = byte read/write.  $8000 = read instead of write.
.save_write_table:
	// Turn PPU off
	dw $1000 | $2100, $80
	dw $1000 | $4200, $00
	// Single address, B bus -> A bus.  B address = reflector to WRAM ($2180).
	dw $0000 | $4310, $8080  // direction = B->A, byte reg, B addr = $2180
	// Copy WRAM 7E0000-7E7FFF to SRAM 710000-717FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0071  // A addr = $71xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $0000  // WRAM addr = $xx0000
	dw $1000 | $2183, $00    // WRAM addr = $7Exxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy WRAM 7E8000-7EFFFF to SRAM 720000-727FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0072  // A addr = $72xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $8000  // WRAM addr = $xx8000
	dw $1000 | $2183, $00    // WRAM addr = $7Exxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy WRAM 7F0000-7F7FFF to SRAM 730000-737FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0073  // A addr = $73xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $0000  // WRAM addr = $xx0000
	dw $1000 | $2183, $01    // WRAM addr = $7Fxxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy WRAM 7F8000-7FFFFF to SRAM 740000-747FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0074  // A addr = $74xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $8000  // WRAM addr = $xx8000
	dw $1000 | $2183, $01    // WRAM addr = $7Fxxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Address pair, B bus -> A bus.  B address = VRAM read ($2139).
	dw $0000 | $4310, $3981  // direction = B->A, word reg, B addr = $2139
	dw $1000 | $2115, $0000  // VRAM address increment mode.
	// Copy VRAM 0000-7FFF to SRAM 750000-757FFF.
	dw $0000 | $2116, $0000  // VRAM address >> 1.
	dw $9000 | $2139, $0000  // VRAM dummy read.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0075  // A addr = $75xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($0000), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy VRAM 8000-7FFF to SRAM 760000-767FFF.
	dw $0000 | $2116, $4000  // VRAM address >> 1.
	dw $9000 | $2139, $0000  // VRAM dummy read.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0076  // A addr = $76xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($0000), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy CGRAM 000-1FF to SRAM 772000-7721FF.
	dw $1000 | $2121, $00    // CGRAM address
	dw $0000 | $4310, $3B80  // direction = B->A, byte reg, B addr = $213B
	dw $0000 | $4312, $2000  // A addr = $xx2000
	dw $0000 | $4314, $0077  // A addr = $77xxxx, size = $xx00
	dw $0000 | $4316, $0002  // size = $02xx ($0200), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy OAM 000-23F to SRAM 772200-77243F.
	dw $0000 | $2102, $0000  // OAM address
	dw $0000 | $4310, $3880  // direction = B->A, byte reg, B addr = $2138
	dw $0000 | $4312, $2200  // A addr = $xx2200
	dw $0000 | $4314, $4077  // A addr = $77xxxx, size = $xx40
	dw $0000 | $4316, $0002  // size = $02xx ($0240), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Done
	dw $0000, .save_return

.save_return:
	// Restore null bank.
	pea $0000
	plb
	plb

	// Save stack pointer.
	rep #$30
	tsa
	sta.l {sram_saved_sp}
	// Save direct pointer.
	tda
	sta.l {sram_saved_dp}

	// Mark the save as valid.
	lda.w #{magic_sram_tag_lo}
	sta.l {sram_validity}
	lda.w #{magic_sram_tag_hi}
	sta.l {sram_validity} + 2

.register_restore_return:
	// Restore register state for return.
	sep #$20
	lda.b {nmi_control_shadow}
	sta.w $4200
	lda.b {hdma_control_shadow}
	sta.w $420C
	lda.b {screen_control_shadow}
	sta.w $2100

	// Copy actual SPC state to shadow SPC state, or the game gets confused.
	lda.w $2142
	sta.l {spc_state_shadow}

	// Return to the game's NMI handler.
	rep #$38
	jml {ram_nmi_after_controller}

// Select and L pushed = load.
.select_l:
	// Clear the bank register, because we don't know how it was set.
	pea $0000
	plb
	plb

	// Check whether SRAM contents are valid.
	lda.l {sram_validity} + 0
	cmp.w #{magic_sram_tag_lo}
	bne .jmp_error_sound
	lda.l {sram_validity} + 2
	cmp.w #{magic_sram_tag_hi}
	bne .jmp_error_sound

	// Stop sound effects by sending command to SPC700
	stz.w $2141    // write zero to both $2141 and $2142
	sep #$20
	stz.w $2143
	lda.b #$F1
	sta.w $2140

	// Save the RNG value to a location that gets loaded after the RNG value.
	// This way, we preserve the RNG value into the loaded state.
	// NOTE: Bank set to 00 above.
	rep #$20
	lda.w {rng_value}
	sta.l {load_temporary_rng}

	// Execute VM to do DMAs
	ldx.w #.load_write_table
.jmp_run_vm:
	jmp .run_vm

.load_after_7E_done:
	lda.l {load_temporary_rng}
	sta.l {rng_value}
	bra .jmp_run_vm

// Needed to put this somewhere.
.jmp_error_sound:
	jmp .error_sound_return

// Register write data table for loading saves.
.load_write_table:
	// Disable HDMA
	dw $1000 | $420C, $00
	// Turn PPU off
	dw $1000 | $2100, $80
	dw $1000 | $4200, $00
	// Single address, A bus -> B bus.  B address = reflector to WRAM ($2180).
	dw $0000 | $4310, $8000  // direction = A->B, B addr = $2180
	// Copy SRAM 710000-717FFF to WRAM 7E0000-7E7FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0071  // A addr = $71xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $0000  // WRAM addr = $xx0000
	dw $1000 | $2183, $00    // WRAM addr = $7Exxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 720000-727FFF to WRAM 7E8000-7EFFFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0072  // A addr = $72xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $8000  // WRAM addr = $xx8000
	dw $1000 | $2183, $00    // WRAM addr = $7Exxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Reload variables from 7E we didn't want to reload from SRAM.
	dw $0000, .load_after_7E_done
	// Copy SRAM 730000-737FFF to WRAM 7F0000-7F7FFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0073  // A addr = $73xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $0000  // WRAM addr = $xx0000
	dw $1000 | $2183, $01    // WRAM addr = $7Fxxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 740000-747FFF to WRAM 7F8000-7FFFFF.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0074  // A addr = $74xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($8000), unused bank reg = $00.
	dw $0000 | $2181, $8000  // WRAM addr = $xx8000
	dw $1000 | $2183, $01    // WRAM addr = $7Fxxxx  (bank is relative to $7E)
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Address pair, A bus -> B bus.  B address = VRAM write ($2118).
	dw $0000 | $4310, $1801  // direction = A->B, B addr = $2118
	dw $1000 | $2115, $0000  // VRAM address increment mode.
	// Copy SRAM 750000-757FFF to VRAM 0000-7FFF.
	dw $0000 | $2116, $0000  // VRAM address >> 1.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0075  // A addr = $75xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($0000), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 760000-767FFF to VRAM 8000-7FFF.
	dw $0000 | $2116, $4000  // VRAM address >> 1.
	dw $0000 | $4312, $0000  // A addr = $xx0000
	dw $0000 | $4314, $0076  // A addr = $76xxxx, size = $xx00
	dw $0000 | $4316, $0080  // size = $80xx ($0000), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 772000-7721FF to CGRAM 000-1FF.
	dw $1000 | $2121, $00    // CGRAM address
	dw $0000 | $4310, $2200  // direction = A->B, byte reg, B addr = $2122
	dw $0000 | $4312, $2000  // A addr = $xx2000
	dw $0000 | $4314, $0077  // A addr = $77xxxx, size = $xx00
	dw $0000 | $4316, $0002  // size = $02xx ($0200), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Copy SRAM 772200-77243F to OAM 000-23F.
	dw $0000 | $2102, $0000  // OAM address
	dw $0000 | $4310, $0400  // direction = A->B, byte reg, B addr = $2104
	dw $0000 | $4312, $2200  // A addr = $xx2200
	dw $0000 | $4314, $4077  // A addr = $77xxxx, size = $xx40
	dw $0000 | $4316, $0002  // size = $02xx ($0240), unused bank reg = $00.
	dw $1000 | $420B, $02    // Trigger DMA on channel 1
	// Done
	dw $0000, .load_return

.load_return:
	// Load stack pointer.  We've been very careful not to use the stack
	// during the memory DMA.  We can now use the saved stack.
	rep #$30
	lda.l {sram_saved_sp}
	tas
	// Load direct pointer.
	lda.l {sram_saved_dp}
	tad

	// Restore null bank now that we have a working stack.
	pea $0000
	plb
	plb

	// Load DMA registers' state from SRAM.
	ldy.w #0
	ldx.w #0

	sep #$20
.load_dma_regs_loop:
	lda.l {sram_dma_bank}, x
	sta.w $4300, x
	inx
	iny
	cpy.w #$000B
	bne .load_dma_regs_loop
	cpx.w #$007B
	beq .load_dma_regs_done
	inx
	inx
	inx
	inx
	inx
	ldy.w #0
	jmp .load_dma_regs_loop
	// End of DMA from SRAM

.load_dma_regs_done:
	// Restore registers and return.
	jmp .register_restore_return

.vm:
	// Data format: xx xx yy yy
	// xxxx = little-endian address to write to .vm's bank
	// yyyy = little-endian value to write
	// If xxxx has high bit set, read and discard instead of write.
	// If xxxx has bit 12 set ($1000), byte instead of word.
	// If yyyy has $DD in the low half, it means that this operation is a byte
	// write instead of a word write.  If xxxx is $0000, end the VM.
	rep #$30
	// Read address to write to
	lda.w $0000, x
	beq .vm_done
	tay
	inx
	inx
	// Check for byte mode
	bit.w #$1000
	beq .vm_word_mode
	and.w #~$1000
	tay
	sep #$20
.vm_word_mode:
	// Read value
	lda.w $0000, x
	inx
	inx
.vm_write:
	// Check for read mode (high bit of address)
	cpy.w #$8000
	bcs .vm_read
	sta $0000, y
	bra .vm
.vm_read:
	// "Subtract" $8000 from y by taking advantage of bank wrapping.
	lda $8000, y
	bra .vm

.vm_done:
	// A, X and Y are 16-bit at exit.
	// Return to caller.  The word in the table after the terminator is the
	// code address to return to.
	// X will be set to the next "instruction" in case resuming the VM
	// is desired.
	inx
	inx
	inx
	inx
	jmp ($FFFE,x)


{loadpc}
