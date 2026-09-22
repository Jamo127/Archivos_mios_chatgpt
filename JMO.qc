/*
==============================================================================
arctic.mdl
==============================================================================
*/

$modelname arctic.mdl
$cd .
$cdtexture ./maps_8bit

$body studio "arctic"
$bodygroup backpack
{
    blank
    studio "bomb"
}

$attachment 0 "Bip01 R Hand" 10.855 -0.416715 1.87068
$attachment 1 "Bip01 L Hand" 10.855 -0.416715 1.87068

$hbox 3 "Bip01 Pelvis" -4.69 -4.44 -6.75  4 5.56 6.75
$hbox 6 "Bip01 L Thigh" 2.66 -3.69 -3.09  18.16 4.88 3.31
$hbox 6 "Bip01 L Calf" 0.38 -3.97 -2.84  17.6 4 2.94
$hbox 6 "Bip01 L Foot" 0.85 -3.24 -2.64  5.73 8.53 3.17
$hbox 7 "Bip01 R Thigh" 2.47 -3.69 -3.16  18.13 4.88 3.38
$hbox 7 "Bip01 R Calf" 0.31 -3.97 -2.84  17.6 3.94 2.97
$hbox 7 "Bip01 R Foot" 0.85 -3.24 -2.64  5.73 8.53 3.17
$hbox 3 "Bip01 Spine1" -3.25 -5.5 -5.5  4.83 5.5 5.5
$hbox 2 "Bip01 Spine2" -0.06 -5.53 -7.59  8 7 7.59
$hbox 2 "Bip01 Spine3" -2.25 -6.81 -6.31  6.5 5.09 6.31
$hbox 2 "Bip01 Neck" -3.11 -1.5 -3  2.05 3.5 3
$hbox 1 "Bip01 Head" -0.33 -4.5 -2.5  8 4.5 2.5
$hbox 4 "Bip01 L Clavicle" 0.94 -2.88 -4.13  5.44 4.28 3.5
$hbox 4 "Bip01 L UpperArm" -2.16 -2.34 -2.56  11.56 3.41 2.38
$hbox 4 "Bip01 L Forearm" 0.59 -1.81 -2.19  10.75 2.84 2.41
$hbox 4 "Bip01 L Hand" -0.132201 -1.90302 -2.23853  4.8629 2.07824 2.36979
$hbox 5 "Bip01 R Clavicle" 1.38 -2.84 -3.56  5.69 4.31 4.31
$hbox 5 "Bip01 R UpperArm" -1.88 -2.47 -2.16  11.81 3.28 2.81
$hbox 5 "Bip01 R Forearm" 0.44 -1.97 -2.34  10.59 2.72 2.22
$hbox 5 "Bip01 R Hand" -0.132201 -1.90302 -2.23853  4.8629 2.07824 2.36979
$hbox 8 "Bip01 L Hand" -16.1 -6.5 -19  10.6 1.5 33

$sequence dummy "./anims/dummy" fps 24 loop
$sequence idle1 {
    "./anims/idle1"
    fps 15
    loop
    ACT_IDLE 1
}
$sequence crouch_idle {
    "./anims/crouch_idle"
    fps 10
    loop
    ACT_CROUCHIDLE 1
}
$sequence walk {
    "./anims/walk"
    fps 30
    loop
    ACT_WALK 1
    LX
}
$sequence run {
    "./anims/run"
    fps 60
    loop
    ACT_RUN 1
    LX
}
$sequence crouchrun {
    "./anims/crouchrun"
    fps 30
    loop
    ACT_CROUCH 1
    LX
}
$sequence jump {
    "./anims/jump"
    fps 36
    ACT_HOP 1
}
$sequence longjump {
    "./anims/longjump"
    fps 36
    ACT_LEAP 1
}
$sequence swim {
    "./anims/swim"
    fps 30
    loop
    ACT_SWIM 1
}
$sequence treadwater {
    "./anims/treadwater"
    fps 24
    loop
    ACT_HOVER 1
}
$sequence crouch_aim_carbine {
    "./anims/crouch_aim_carbine_blend_00"
    "./anims/crouch_aim_carbine_blend_01"
    "./anims/crouch_aim_carbine_blend_02"
    "./anims/crouch_aim_carbine_blend_03"
    "./anims/crouch_aim_carbine_blend_04"
    "./anims/crouch_aim_carbine_blend_05"
    "./anims/crouch_aim_carbine_blend_06"
    "./anims/crouch_aim_carbine_blend_07"
    "./anims/crouch_aim_carbine_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_shoot_carbine {
    "./anims/crouch_shoot_carbine_blend_00"
    "./anims/crouch_shoot_carbine_blend_01"
    "./anims/crouch_shoot_carbine_blend_02"
    "./anims/crouch_shoot_carbine_blend_03"
    "./anims/crouch_shoot_carbine_blend_04"
    "./anims/crouch_shoot_carbine_blend_05"
    "./anims/crouch_shoot_carbine_blend_06"
    "./anims/crouch_shoot_carbine_blend_07"
    "./anims/crouch_shoot_carbine_blend_08"
    fps 15
    blend XR -90 90
    { event 5001 0 "40" }
}
$sequence crouch_reload_carbine "./anims/crouch_reload_carbine" fps 30
$sequence ref_aim_carbine {
    "./anims/ref_aim_carbine_blend_00"
    "./anims/ref_aim_carbine_blend_01"
    "./anims/ref_aim_carbine_blend_02"
    "./anims/ref_aim_carbine_blend_03"
    "./anims/ref_aim_carbine_blend_04"
    "./anims/ref_aim_carbine_blend_05"
    "./anims/ref_aim_carbine_blend_06"
    "./anims/ref_aim_carbine_blend_07"
    "./anims/ref_aim_carbine_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence ref_shoot_carbine {
    "./anims/ref_shoot_carbine_blend_00"
    "./anims/ref_shoot_carbine_blend_01"
    "./anims/ref_shoot_carbine_blend_02"
    "./anims/ref_shoot_carbine_blend_03"
    "./anims/ref_shoot_carbine_blend_04"
    "./anims/ref_shoot_carbine_blend_05"
    "./anims/ref_shoot_carbine_blend_06"
    "./anims/ref_shoot_carbine_blend_07"
    "./anims/ref_shoot_carbine_blend_08"
    fps 15
    blend XR -90 90
    { event 5001 0 "40" }
}
$sequence ref_reload_carbine "./anims/ref_reload_carbine" fps 30
$sequence crouch_aim_onehanded {
    "./anims/crouch_aim_onehanded_blend_00"
    "./anims/crouch_aim_onehanded_blend_01"
    "./anims/crouch_aim_onehanded_blend_02"
    "./anims/crouch_aim_onehanded_blend_03"
    "./anims/crouch_aim_onehanded_blend_04"
    "./anims/crouch_aim_onehanded_blend_05"
    "./anims/crouch_aim_onehanded_blend_06"
    "./anims/crouch_aim_onehanded_blend_07"
    "./anims/crouch_aim_onehanded_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_shoot_onehanded {
    "./anims/crouch_shoot_onehanded_blend_00"
    "./anims/crouch_shoot_onehanded_blend_01"
    "./anims/crouch_shoot_onehanded_blend_02"
    "./anims/crouch_shoot_onehanded_blend_03"
    "./anims/crouch_shoot_onehanded_blend_04"
    "./anims/crouch_shoot_onehanded_blend_05"
    "./anims/crouch_shoot_onehanded_blend_06"
    "./anims/crouch_shoot_onehanded_blend_07"
    "./anims/crouch_shoot_onehanded_blend_08"
    fps 15
    blend XR -90 90
    { event 5001 0 "10" }
}
$sequence crouch_reload_onehanded "./anims/crouch_reload_onehanded" fps 30
$sequence ref_aim_onehanded {
    "./anims/ref_aim_onehanded_blend_00"
    "./anims/ref_aim_onehanded_blend_01"
    "./anims/ref_aim_onehanded_blend_02"
    "./anims/ref_aim_onehanded_blend_03"
    "./anims/ref_aim_onehanded_blend_04"
    "./anims/ref_aim_onehanded_blend_05"
    "./anims/ref_aim_onehanded_blend_06"
    "./anims/ref_aim_onehanded_blend_07"
    "./anims/ref_aim_onehanded_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence ref_shoot_onehanded {
    "./anims/ref_shoot_onehanded_blend_00"
    "./anims/ref_shoot_onehanded_blend_01"
    "./anims/ref_shoot_onehanded_blend_02"
    "./anims/ref_shoot_onehanded_blend_03"
    "./anims/ref_shoot_onehanded_blend_04"
    "./anims/ref_shoot_onehanded_blend_05"
    "./anims/ref_shoot_onehanded_blend_06"
    "./anims/ref_shoot_onehanded_blend_07"
    "./anims/ref_shoot_onehanded_blend_08"
    fps 15
    blend XR -90 90
    { event 5001 0 "10" }
}
$sequence ref_reload_onehanded "./anims/ref_reload_onehanded" fps 30
$sequence crouch_aim_dualpistols_1 {
    "./anims/crouch_aim_dualpistols_1_blend_00"
    "./anims/crouch_aim_dualpistols_1_blend_01"
    "./anims/crouch_aim_dualpistols_1_blend_02"
    "./anims/crouch_aim_dualpistols_1_blend_03"
    "./anims/crouch_aim_dualpistols_1_blend_04"
    "./anims/crouch_aim_dualpistols_1_blend_05"
    "./anims/crouch_aim_dualpistols_1_blend_06"
    "./anims/crouch_aim_dualpistols_1_blend_07"
    "./anims/crouch_aim_dualpistols_1_blend_08"
    fps 10
    loop
    blend XR -90 90
}
$sequence crouch_shoot_dualpistols_1 {
    "./anims/crouch_shoot_dualpistols_1_blend_00"
    "./anims/crouch_shoot_dualpistols_1_blend_01"
    "./anims/crouch_shoot_dualpistols_1_blend_02"
    "./anims/crouch_shoot_dualpistols_1_blend_03"
    "./anims/crouch_shoot_dualpistols_1_blend_04"
    "./anims/crouch_shoot_dualpistols_1_blend_05"
    "./anims/crouch_shoot_dualpistols_1_blend_06"
    "./anims/crouch_shoot_dualpistols_1_blend_07"
    "./anims/crouch_shoot_dualpistols_1_blend_08"
    fps 30
    blend XR -90 90
    { event 5011 0 "10" }
}
$sequence crouch_shoot2_dualpistols_1 {
    "./anims/crouch_shoot2_dualpistols_1_blend_00"
    "./anims/crouch_shoot2_dualpistols_1_blend_01"
    "./anims/crouch_shoot2_dualpistols_1_blend_02"
    "./anims/crouch_shoot2_dualpistols_1_blend_03"
    "./anims/crouch_shoot2_dualpistols_1_blend_04"
    "./anims/crouch_shoot2_dualpistols_1_blend_05"
    "./anims/crouch_shoot2_dualpistols_1_blend_06"
    "./anims/crouch_shoot2_dualpistols_1_blend_07"
    "./anims/crouch_shoot2_dualpistols_1_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "10" }
}
$sequence crouch_reload_dualpistols_1 "./anims/crouch_reload_dualpistols_1" fps 30
$sequence ref_aim_dualpistols_1 {
    "./anims/ref_aim_dualpistols_1_blend_00"
    "./anims/ref_aim_dualpistols_1_blend_01"
    "./anims/ref_aim_dualpistols_1_blend_02"
    "./anims/ref_aim_dualpistols_1_blend_03"
    "./anims/ref_aim_dualpistols_1_blend_04"
    "./anims/ref_aim_dualpistols_1_blend_05"
    "./anims/ref_aim_dualpistols_1_blend_06"
    "./anims/ref_aim_dualpistols_1_blend_07"
    "./anims/ref_aim_dualpistols_1_blend_08"
    fps 10
    loop
    blend XR -90 90
}
$sequence ref_shoot_dualpistols_1 {
    "./anims/ref_shoot_dualpistols_1_blend_00"
    "./anims/ref_shoot_dualpistols_1_blend_01"
    "./anims/ref_shoot_dualpistols_1_blend_02"
    "./anims/ref_shoot_dualpistols_1_blend_03"
    "./anims/ref_shoot_dualpistols_1_blend_04"
    "./anims/ref_shoot_dualpistols_1_blend_05"
    "./anims/ref_shoot_dualpistols_1_blend_06"
    "./anims/ref_shoot_dualpistols_1_blend_07"
    "./anims/ref_shoot_dualpistols_1_blend_08"
    fps 30
    blend XR -90 90
    { event 5011 0 "10" }
}
$sequence ref_shoot2_dualpistols_1 {
    "./anims/ref_shoot2_dualpistols_1_blend_00"
    "./anims/ref_shoot2_dualpistols_1_blend_01"
    "./anims/ref_shoot2_dualpistols_1_blend_02"
    "./anims/ref_shoot2_dualpistols_1_blend_03"
    "./anims/ref_shoot2_dualpistols_1_blend_04"
    "./anims/ref_shoot2_dualpistols_1_blend_05"
    "./anims/ref_shoot2_dualpistols_1_blend_06"
    "./anims/ref_shoot2_dualpistols_1_blend_07"
    "./anims/ref_shoot2_dualpistols_1_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "10" }
}
$sequence ref_reload_dualpistols_1 "./anims/ref_reload_dualpistols_1" fps 30
$sequence crouch_aim_rifle {
    "./anims/crouch_aim_rifle_blend_00"
    "./anims/crouch_aim_rifle_blend_01"
    "./anims/crouch_aim_rifle_blend_02"
    "./anims/crouch_aim_rifle_blend_03"
    "./anims/crouch_aim_rifle_blend_04"
    "./anims/crouch_aim_rifle_blend_05"
    "./anims/crouch_aim_rifle_blend_06"
    "./anims/crouch_aim_rifle_blend_07"
    "./anims/crouch_aim_rifle_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_shoot_rifle {
    "./anims/crouch_shoot_rifle_blend_00"
    "./anims/crouch_shoot_rifle_blend_01"
    "./anims/crouch_shoot_rifle_blend_02"
    "./anims/crouch_shoot_rifle_blend_03"
    "./anims/crouch_shoot_rifle_blend_04"
    "./anims/crouch_shoot_rifle_blend_05"
    "./anims/crouch_shoot_rifle_blend_06"
    "./anims/crouch_shoot_rifle_blend_07"
    "./anims/crouch_shoot_rifle_blend_08"
    fps 20
    blend XR -90 90
    { event 5001 0 "30" }
}
$sequence crouch_reload_rifle "./anims/crouch_reload_rifle" fps 30
$sequence ref_aim_rifle {
    "./anims/ref_aim_rifle_blend_00"
    "./anims/ref_aim_rifle_blend_01"
    "./anims/ref_aim_rifle_blend_02"
    "./anims/ref_aim_rifle_blend_03"
    "./anims/ref_aim_rifle_blend_04"
    "./anims/ref_aim_rifle_blend_05"
    "./anims/ref_aim_rifle_blend_06"
    "./anims/ref_aim_rifle_blend_07"
    "./anims/ref_aim_rifle_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence ref_shoot_rifle {
    "./anims/ref_shoot_rifle_blend_00"
    "./anims/ref_shoot_rifle_blend_01"
    "./anims/ref_shoot_rifle_blend_02"
    "./anims/ref_shoot_rifle_blend_03"
    "./anims/ref_shoot_rifle_blend_04"
    "./anims/ref_shoot_rifle_blend_05"
    "./anims/ref_shoot_rifle_blend_06"
    "./anims/ref_shoot_rifle_blend_07"
    "./anims/ref_shoot_rifle_blend_08"
    fps 20
    blend XR -90 90
    { event 5001 0 "30" }
}
$sequence ref_reload_rifle "./anims/ref_reload_rifle" fps 30
$sequence crouch_aim_mp5 {
    "./anims/crouch_aim_mp5_blend_00"
    "./anims/crouch_aim_mp5_blend_01"
    "./anims/crouch_aim_mp5_blend_02"
    "./anims/crouch_aim_mp5_blend_03"
    "./anims/crouch_aim_mp5_blend_04"
    "./anims/crouch_aim_mp5_blend_05"
    "./anims/crouch_aim_mp5_blend_06"
    "./anims/crouch_aim_mp5_blend_07"
    "./anims/crouch_aim_mp5_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_shoot_mp5 {
    "./anims/crouch_shoot_mp5_blend_00"
    "./anims/crouch_shoot_mp5_blend_01"
    "./anims/crouch_shoot_mp5_blend_02"
    "./anims/crouch_shoot_mp5_blend_03"
    "./anims/crouch_shoot_mp5_blend_04"
    "./anims/crouch_shoot_mp5_blend_05"
    "./anims/crouch_shoot_mp5_blend_06"
    "./anims/crouch_shoot_mp5_blend_07"
    "./anims/crouch_shoot_mp5_blend_08"
    fps 15
    blend XR -90 90
    { event 5001 0 "30" }
}
$sequence crouch_reload_mp5 "./anims/crouch_reload_mp5" fps 30
$sequence ref_aim_mp5 {
    "./anims/ref_aim_mp5_blend_00"
    "./anims/ref_aim_mp5_blend_01"
    "./anims/ref_aim_mp5_blend_02"
    "./anims/ref_aim_mp5_blend_03"
    "./anims/ref_aim_mp5_blend_04"
    "./anims/ref_aim_mp5_blend_05"
    "./anims/ref_aim_mp5_blend_06"
    "./anims/ref_aim_mp5_blend_07"
    "./anims/ref_aim_mp5_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence ref_shoot_mp5 {
    "./anims/ref_shoot_mp5_blend_00"
    "./anims/ref_shoot_mp5_blend_01"
    "./anims/ref_shoot_mp5_blend_02"
    "./anims/ref_shoot_mp5_blend_03"
    "./anims/ref_shoot_mp5_blend_04"
    "./anims/ref_shoot_mp5_blend_05"
    "./anims/ref_shoot_mp5_blend_06"
    "./anims/ref_shoot_mp5_blend_07"
    "./anims/ref_shoot_mp5_blend_08"
    fps 15
    blend XR -90 90
    { event 5001 0 "30" }
}
$sequence ref_reload_mp5 "./anims/ref_reload_mp5" fps 30
$sequence crouch_aim_shotgun {
    "./anims/crouch_aim_shotgun_blend_00"
    "./anims/crouch_aim_shotgun_blend_01"
    "./anims/crouch_aim_shotgun_blend_02"
    "./anims/crouch_aim_shotgun_blend_03"
    "./anims/crouch_aim_shotgun_blend_04"
    "./anims/crouch_aim_shotgun_blend_05"
    "./anims/crouch_aim_shotgun_blend_06"
    "./anims/crouch_aim_shotgun_blend_07"
    "./anims/crouch_aim_shotgun_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_shoot_shotgun {
    "./anims/crouch_shoot_shotgun_blend_00"
    "./anims/crouch_shoot_shotgun_blend_01"
    "./anims/crouch_shoot_shotgun_blend_02"
    "./anims/crouch_shoot_shotgun_blend_03"
    "./anims/crouch_shoot_shotgun_blend_04"
    "./anims/crouch_shoot_shotgun_blend_05"
    "./anims/crouch_shoot_shotgun_blend_06"
    "./anims/crouch_shoot_shotgun_blend_07"
    "./anims/crouch_shoot_shotgun_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "50" }
}
$sequence crouch_reload_shotgun "./anims/crouch_reload_shotgun" fps 30
$sequence ref_aim_shotgun {
    "./anims/ref_aim_shotgun_blend_00"
    "./anims/ref_aim_shotgun_blend_01"
    "./anims/ref_aim_shotgun_blend_02"
    "./anims/ref_aim_shotgun_blend_03"
    "./anims/ref_aim_shotgun_blend_04"
    "./anims/ref_aim_shotgun_blend_05"
    "./anims/ref_aim_shotgun_blend_06"
    "./anims/ref_aim_shotgun_blend_07"
    "./anims/ref_aim_shotgun_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence ref_shoot_shotgun {
    "./anims/ref_shoot_shotgun_blend_00"
    "./anims/ref_shoot_shotgun_blend_01"
    "./anims/ref_shoot_shotgun_blend_02"
    "./anims/ref_shoot_shotgun_blend_03"
    "./anims/ref_shoot_shotgun_blend_04"
    "./anims/ref_shoot_shotgun_blend_05"
    "./anims/ref_shoot_shotgun_blend_06"
    "./anims/ref_shoot_shotgun_blend_07"
    "./anims/ref_shoot_shotgun_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "50" }
}
$sequence ref_reload_shotgun "./anims/ref_reload_shotgun" fps 30
$sequence crouch_aim_m249 {
    "./anims/crouch_aim_m249_blend_00"
    "./anims/crouch_aim_m249_blend_01"
    "./anims/crouch_aim_m249_blend_02"
    "./anims/crouch_aim_m249_blend_03"
    "./anims/crouch_aim_m249_blend_04"
    "./anims/crouch_aim_m249_blend_05"
    "./anims/crouch_aim_m249_blend_06"
    "./anims/crouch_aim_m249_blend_07"
    "./anims/crouch_aim_m249_blend_08"
    fps 10
    loop
    blend XR -90 90
}
$sequence crouch_shoot_m249 {
    "./anims/crouch_shoot_m249_blend_00"
    "./anims/crouch_shoot_m249_blend_01"
    "./anims/crouch_shoot_m249_blend_02"
    "./anims/crouch_shoot_m249_blend_03"
    "./anims/crouch_shoot_m249_blend_04"
    "./anims/crouch_shoot_m249_blend_05"
    "./anims/crouch_shoot_m249_blend_06"
    "./anims/crouch_shoot_m249_blend_07"
    "./anims/crouch_shoot_m249_blend_08"
    fps 30
    loop
    blend XR -90 90
    { event 5001 0 "50" }
}
$sequence crouch_reload_m249 "./anims/crouch_reload_m249" fps 30
$sequence ref_aim_m249 {
    "./anims/ref_aim_m249_blend_00"
    "./anims/ref_aim_m249_blend_01"
    "./anims/ref_aim_m249_blend_02"
    "./anims/ref_aim_m249_blend_03"
    "./anims/ref_aim_m249_blend_04"
    "./anims/ref_aim_m249_blend_05"
    "./anims/ref_aim_m249_blend_06"
    "./anims/ref_aim_m249_blend_07"
    "./anims/ref_aim_m249_blend_08"
    fps 10
    loop
    blend XR -90 90
}
$sequence ref_shoot_m249 {
    "./anims/ref_shoot_m249_blend_00"
    "./anims/ref_shoot_m249_blend_01"
    "./anims/ref_shoot_m249_blend_02"
    "./anims/ref_shoot_m249_blend_03"
    "./anims/ref_shoot_m249_blend_04"
    "./anims/ref_shoot_m249_blend_05"
    "./anims/ref_shoot_m249_blend_06"
    "./anims/ref_shoot_m249_blend_07"
    "./anims/ref_shoot_m249_blend_08"
    fps 30
    loop
    blend XR -90 90
    { event 5001 0 "50" }
}
$sequence ref_reload_m249 "./anims/ref_reload_m249" fps 30
$sequence I_am_a_stupid_placeholder "./anims/i_am_a_stupid_placeholder" fps 30 loop
$sequence so_am_I "./anims/so_am_i" fps 30
$sequence ref_aim_grenade {
    "./anims/ref_aim_grenade_blend_00"
    "./anims/ref_aim_grenade_blend_01"
    "./anims/ref_aim_grenade_blend_02"
    "./anims/ref_aim_grenade_blend_03"
    "./anims/ref_aim_grenade_blend_04"
    "./anims/ref_aim_grenade_blend_05"
    "./anims/ref_aim_grenade_blend_06"
    "./anims/ref_aim_grenade_blend_07"
    "./anims/ref_aim_grenade_blend_08"
    fps 20
    loop
    blend XR -90 90
}
$sequence ref_shoot_grenade {
    "./anims/ref_shoot_grenade_blend_00"
    "./anims/ref_shoot_grenade_blend_01"
    "./anims/ref_shoot_grenade_blend_02"
    "./anims/ref_shoot_grenade_blend_03"
    "./anims/ref_shoot_grenade_blend_04"
    "./anims/ref_shoot_grenade_blend_05"
    "./anims/ref_shoot_grenade_blend_06"
    "./anims/ref_shoot_grenade_blend_07"
    "./anims/ref_shoot_grenade_blend_08"
    fps 45
    blend XR -90 90
}
$sequence crouch_aim_grenade {
    "./anims/crouch_aim_grenade_blend_00"
    "./anims/crouch_aim_grenade_blend_01"
    "./anims/crouch_aim_grenade_blend_02"
    "./anims/crouch_aim_grenade_blend_03"
    "./anims/crouch_aim_grenade_blend_04"
    "./anims/crouch_aim_grenade_blend_05"
    "./anims/crouch_aim_grenade_blend_06"
    "./anims/crouch_aim_grenade_blend_07"
    "./anims/crouch_aim_grenade_blend_08"
    fps 20
    loop
    blend XR -90 90
}
$sequence crouch_shoot_grenade {
    "./anims/crouch_shoot_grenade_blend_00"
    "./anims/crouch_shoot_grenade_blend_01"
    "./anims/crouch_shoot_grenade_blend_02"
    "./anims/crouch_shoot_grenade_blend_03"
    "./anims/crouch_shoot_grenade_blend_04"
    "./anims/crouch_shoot_grenade_blend_05"
    "./anims/crouch_shoot_grenade_blend_06"
    "./anims/crouch_shoot_grenade_blend_07"
    "./anims/crouch_shoot_grenade_blend_08"
    fps 45
    blend XR -90 90
}
$sequence crouch_aim_c4 {
    "./anims/crouch_aim_c4_blend_00"
    "./anims/crouch_aim_c4_blend_01"
    "./anims/crouch_aim_c4_blend_02"
    "./anims/crouch_aim_c4_blend_03"
    "./anims/crouch_aim_c4_blend_04"
    "./anims/crouch_aim_c4_blend_05"
    "./anims/crouch_aim_c4_blend_06"
    "./anims/crouch_aim_c4_blend_07"
    "./anims/crouch_aim_c4_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_shoot_c4 "./anims/crouch_shoot_c4" fps 30
$sequence ref_aim_c4 {
    "./anims/ref_aim_c4_blend_00"
    "./anims/ref_aim_c4_blend_01"
    "./anims/ref_aim_c4_blend_02"
    "./anims/ref_aim_c4_blend_03"
    "./anims/ref_aim_c4_blend_04"
    "./anims/ref_aim_c4_blend_05"
    "./anims/ref_aim_c4_blend_06"
    "./anims/ref_aim_c4_blend_07"
    "./anims/ref_aim_c4_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence ref_shoot_c4 "./anims/ref_shoot_c4" fps 30
$sequence ref_reload_c4 "./anims/ref_reload_c4" fps 30
$sequence crouch_aim_dualpistols_2 {
    "./anims/crouch_aim_dualpistols_2_blend_00"
    "./anims/crouch_aim_dualpistols_2_blend_01"
    "./anims/crouch_aim_dualpistols_2_blend_02"
    "./anims/crouch_aim_dualpistols_2_blend_03"
    "./anims/crouch_aim_dualpistols_2_blend_04"
    "./anims/crouch_aim_dualpistols_2_blend_05"
    "./anims/crouch_aim_dualpistols_2_blend_06"
    "./anims/crouch_aim_dualpistols_2_blend_07"
    "./anims/crouch_aim_dualpistols_2_blend_08"
    fps 10
    loop
    blend XR -90 90
}
$sequence crouch_shoot_dualpistols_2 {
    "./anims/crouch_shoot_dualpistols_2_blend_00"
    "./anims/crouch_shoot_dualpistols_2_blend_01"
    "./anims/crouch_shoot_dualpistols_2_blend_02"
    "./anims/crouch_shoot_dualpistols_2_blend_03"
    "./anims/crouch_shoot_dualpistols_2_blend_04"
    "./anims/crouch_shoot_dualpistols_2_blend_05"
    "./anims/crouch_shoot_dualpistols_2_blend_06"
    "./anims/crouch_shoot_dualpistols_2_blend_07"
    "./anims/crouch_shoot_dualpistols_2_blend_08"
    fps 30
    blend XR -90 90
    { event 5011 0 "10" }
}
$sequence crouch_shoot2_dualpistols_2 {
    "./anims/crouch_shoot2_dualpistols_2_blend_00"
    "./anims/crouch_shoot2_dualpistols_2_blend_01"
    "./anims/crouch_shoot2_dualpistols_2_blend_02"
    "./anims/crouch_shoot2_dualpistols_2_blend_03"
    "./anims/crouch_shoot2_dualpistols_2_blend_04"
    "./anims/crouch_shoot2_dualpistols_2_blend_05"
    "./anims/crouch_shoot2_dualpistols_2_blend_06"
    "./anims/crouch_shoot2_dualpistols_2_blend_07"
    "./anims/crouch_shoot2_dualpistols_2_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "10" }
}
$sequence crouch_reload_dualpistols_2 "./anims/crouch_reload_dualpistols_2" fps 30
$sequence ref_aim_dualpistols_2 {
    "./anims/ref_aim_dualpistols_2_blend_00"
    "./anims/ref_aim_dualpistols_2_blend_01"
    "./anims/ref_aim_dualpistols_2_blend_02"
    "./anims/ref_aim_dualpistols_2_blend_03"
    "./anims/ref_aim_dualpistols_2_blend_04"
    "./anims/ref_aim_dualpistols_2_blend_05"
    "./anims/ref_aim_dualpistols_2_blend_06"
    "./anims/ref_aim_dualpistols_2_blend_07"
    "./anims/ref_aim_dualpistols_2_blend_08"
    fps 10
    loop
    blend XR -90 90
}
$sequence ref_shoot_dualpistols_2 {
    "./anims/ref_shoot_dualpistols_2_blend_00"
    "./anims/ref_shoot_dualpistols_2_blend_01"
    "./anims/ref_shoot_dualpistols_2_blend_02"
    "./anims/ref_shoot_dualpistols_2_blend_03"
    "./anims/ref_shoot_dualpistols_2_blend_04"
    "./anims/ref_shoot_dualpistols_2_blend_05"
    "./anims/ref_shoot_dualpistols_2_blend_06"
    "./anims/ref_shoot_dualpistols_2_blend_07"
    "./anims/ref_shoot_dualpistols_2_blend_08"
    fps 30
    blend XR -90 90
    { event 5011 0 "10" }
}
$sequence ref_shoot2_dualpistols_2 {
    "./anims/ref_shoot2_dualpistols_2_blend_00"
    "./anims/ref_shoot2_dualpistols_2_blend_01"
    "./anims/ref_shoot2_dualpistols_2_blend_02"
    "./anims/ref_shoot2_dualpistols_2_blend_03"
    "./anims/ref_shoot2_dualpistols_2_blend_04"
    "./anims/ref_shoot2_dualpistols_2_blend_05"
    "./anims/ref_shoot2_dualpistols_2_blend_06"
    "./anims/ref_shoot2_dualpistols_2_blend_07"
    "./anims/ref_shoot2_dualpistols_2_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "10" }
}
$sequence ref_reload_dualpistols_2 "./anims/ref_reload_dualpistols_2" fps 30
$sequence crouch_aim_knife {
    "./anims/crouch_aim_knife_blend_00"
    "./anims/crouch_aim_knife_blend_01"
    "./anims/crouch_aim_knife_blend_02"
    "./anims/crouch_aim_knife_blend_03"
    "./anims/crouch_aim_knife_blend_04"
    "./anims/crouch_aim_knife_blend_05"
    "./anims/crouch_aim_knife_blend_06"
    "./anims/crouch_aim_knife_blend_07"
    "./anims/crouch_aim_knife_blend_08"
    fps 12
    loop
    blend XR -90 90
}
$sequence crouch_shoot_knife {
    "./anims/crouch_shoot_knife_blend_00"
    "./anims/crouch_shoot_knife_blend_01"
    "./anims/crouch_shoot_knife_blend_02"
    "./anims/crouch_shoot_knife_blend_03"
    "./anims/crouch_shoot_knife_blend_04"
    "./anims/crouch_shoot_knife_blend_05"
    "./anims/crouch_shoot_knife_blend_06"
    "./anims/crouch_shoot_knife_blend_07"
    "./anims/crouch_shoot_knife_blend_08"
    fps 30
    blend XR -90 90
}
$sequence ref_aim_knife {
    "./anims/ref_aim_knife_blend_00"
    "./anims/ref_aim_knife_blend_01"
    "./anims/ref_aim_knife_blend_02"
    "./anims/ref_aim_knife_blend_03"
    "./anims/ref_aim_knife_blend_04"
    "./anims/ref_aim_knife_blend_05"
    "./anims/ref_aim_knife_blend_06"
    "./anims/ref_aim_knife_blend_07"
    "./anims/ref_aim_knife_blend_08"
    fps 12
    loop
    blend XR -90 90
}
$sequence ref_shoot_knife {
    "./anims/ref_shoot_knife_blend_00"
    "./anims/ref_shoot_knife_blend_01"
    "./anims/ref_shoot_knife_blend_02"
    "./anims/ref_shoot_knife_blend_03"
    "./anims/ref_shoot_knife_blend_04"
    "./anims/ref_shoot_knife_blend_05"
    "./anims/ref_shoot_knife_blend_06"
    "./anims/ref_shoot_knife_blend_07"
    "./anims/ref_shoot_knife_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_aim_ak47 {
    "./anims/crouch_aim_ak47_blend_00"
    "./anims/crouch_aim_ak47_blend_01"
    "./anims/crouch_aim_ak47_blend_02"
    "./anims/crouch_aim_ak47_blend_03"
    "./anims/crouch_aim_ak47_blend_04"
    "./anims/crouch_aim_ak47_blend_05"
    "./anims/crouch_aim_ak47_blend_06"
    "./anims/crouch_aim_ak47_blend_07"
    "./anims/crouch_aim_ak47_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_shoot_ak47 {
    "./anims/crouch_shoot_ak47_blend_00"
    "./anims/crouch_shoot_ak47_blend_01"
    "./anims/crouch_shoot_ak47_blend_02"
    "./anims/crouch_shoot_ak47_blend_03"
    "./anims/crouch_shoot_ak47_blend_04"
    "./anims/crouch_shoot_ak47_blend_05"
    "./anims/crouch_shoot_ak47_blend_06"
    "./anims/crouch_shoot_ak47_blend_07"
    "./anims/crouch_shoot_ak47_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "40" }
}
$sequence crouch_reload_ak47 "./anims/crouch_reload_ak47" fps 30
$sequence ref_aim_ak47 {
    "./anims/ref_aim_ak47_blend_00"
    "./anims/ref_aim_ak47_blend_01"
    "./anims/ref_aim_ak47_blend_02"
    "./anims/ref_aim_ak47_blend_03"
    "./anims/ref_aim_ak47_blend_04"
    "./anims/ref_aim_ak47_blend_05"
    "./anims/ref_aim_ak47_blend_06"
    "./anims/ref_aim_ak47_blend_07"
    "./anims/ref_aim_ak47_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence ref_shoot_ak47 {
    "./anims/ref_shoot_ak47_blend_00"
    "./anims/ref_shoot_ak47_blend_01"
    "./anims/ref_shoot_ak47_blend_02"
    "./anims/ref_shoot_ak47_blend_03"
    "./anims/ref_shoot_ak47_blend_04"
    "./anims/ref_shoot_ak47_blend_05"
    "./anims/ref_shoot_ak47_blend_06"
    "./anims/ref_shoot_ak47_blend_07"
    "./anims/ref_shoot_ak47_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "40" }
}
$sequence ref_reload_ak47 "./anims/ref_reload_ak47" fps 30
$sequence crouch_aim_shieldgren {
    "./anims/crouch_aim_shieldgren_blend_00"
    "./anims/crouch_aim_shieldgren_blend_01"
    "./anims/crouch_aim_shieldgren_blend_02"
    "./anims/crouch_aim_shieldgren_blend_03"
    "./anims/crouch_aim_shieldgren_blend_04"
    "./anims/crouch_aim_shieldgren_blend_05"
    "./anims/crouch_aim_shieldgren_blend_06"
    "./anims/crouch_aim_shieldgren_blend_07"
    "./anims/crouch_aim_shieldgren_blend_08"
    fps 20
    loop
    blend XR -90 90
}
$sequence crouch_shoot_shieldgren {
    "./anims/crouch_shoot_shieldgren_blend_00"
    "./anims/crouch_shoot_shieldgren_blend_01"
    "./anims/crouch_shoot_shieldgren_blend_02"
    "./anims/crouch_shoot_shieldgren_blend_03"
    "./anims/crouch_shoot_shieldgren_blend_04"
    "./anims/crouch_shoot_shieldgren_blend_05"
    "./anims/crouch_shoot_shieldgren_blend_06"
    "./anims/crouch_shoot_shieldgren_blend_07"
    "./anims/crouch_shoot_shieldgren_blend_08"
    fps 45
    blend XR -90 90
}
$sequence ref_aim_shieldgren {
    "./anims/ref_aim_shieldgren_blend_00"
    "./anims/ref_aim_shieldgren_blend_01"
    "./anims/ref_aim_shieldgren_blend_02"
    "./anims/ref_aim_shieldgren_blend_03"
    "./anims/ref_aim_shieldgren_blend_04"
    "./anims/ref_aim_shieldgren_blend_05"
    "./anims/ref_aim_shieldgren_blend_06"
    "./anims/ref_aim_shieldgren_blend_07"
    "./anims/ref_aim_shieldgren_blend_08"
    fps 20
    loop
    blend XR -90 90
}
$sequence ref_shoot_shieldgren {
    "./anims/ref_shoot_shieldgren_blend_00"
    "./anims/ref_shoot_shieldgren_blend_01"
    "./anims/ref_shoot_shieldgren_blend_02"
    "./anims/ref_shoot_shieldgren_blend_03"
    "./anims/ref_shoot_shieldgren_blend_04"
    "./anims/ref_shoot_shieldgren_blend_05"
    "./anims/ref_shoot_shieldgren_blend_06"
    "./anims/ref_shoot_shieldgren_blend_07"
    "./anims/ref_shoot_shieldgren_blend_08"
    fps 45
    blend XR -90 90
}
$sequence crouch_aim_shieldknife {
    "./anims/crouch_aim_shieldknife_blend_00"
    "./anims/crouch_aim_shieldknife_blend_01"
    "./anims/crouch_aim_shieldknife_blend_02"
    "./anims/crouch_aim_shieldknife_blend_03"
    "./anims/crouch_aim_shieldknife_blend_04"
    "./anims/crouch_aim_shieldknife_blend_05"
    "./anims/crouch_aim_shieldknife_blend_06"
    "./anims/crouch_aim_shieldknife_blend_07"
    "./anims/crouch_aim_shieldknife_blend_08"
    fps 12
    loop
    blend XR -90 90
}
$sequence crouch_shoot_shieldknife {
    "./anims/crouch_shoot_shieldknife_blend_00"
    "./anims/crouch_shoot_shieldknife_blend_01"
    "./anims/crouch_shoot_shieldknife_blend_02"
    "./anims/crouch_shoot_shieldknife_blend_03"
    "./anims/crouch_shoot_shieldknife_blend_04"
    "./anims/crouch_shoot_shieldknife_blend_05"
    "./anims/crouch_shoot_shieldknife_blend_06"
    "./anims/crouch_shoot_shieldknife_blend_07"
    "./anims/crouch_shoot_shieldknife_blend_08"
    fps 30
    blend XR -90 90
}
$sequence ref_aim_shieldknife {
    "./anims/ref_aim_shieldknife_blend_00"
    "./anims/ref_aim_shieldknife_blend_01"
    "./anims/ref_aim_shieldknife_blend_02"
    "./anims/ref_aim_shieldknife_blend_03"
    "./anims/ref_aim_shieldknife_blend_04"
    "./anims/ref_aim_shieldknife_blend_05"
    "./anims/ref_aim_shieldknife_blend_06"
    "./anims/ref_aim_shieldknife_blend_07"
    "./anims/ref_aim_shieldknife_blend_08"
    fps 12
    loop
    blend XR -90 90
}
$sequence ref_shoot_shieldknife {
    "./anims/ref_shoot_shieldknife_blend_00"
    "./anims/ref_shoot_shieldknife_blend_01"
    "./anims/ref_shoot_shieldknife_blend_02"
    "./anims/ref_shoot_shieldknife_blend_03"
    "./anims/ref_shoot_shieldknife_blend_04"
    "./anims/ref_shoot_shieldknife_blend_05"
    "./anims/ref_shoot_shieldknife_blend_06"
    "./anims/ref_shoot_shieldknife_blend_07"
    "./anims/ref_shoot_shieldknife_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_aim_shieldgun {
    "./anims/crouch_aim_shieldgun_blend_00"
    "./anims/crouch_aim_shieldgun_blend_01"
    "./anims/crouch_aim_shieldgun_blend_02"
    "./anims/crouch_aim_shieldgun_blend_03"
    "./anims/crouch_aim_shieldgun_blend_04"
    "./anims/crouch_aim_shieldgun_blend_05"
    "./anims/crouch_aim_shieldgun_blend_06"
    "./anims/crouch_aim_shieldgun_blend_07"
    "./anims/crouch_aim_shieldgun_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence crouch_shoot_shieldgun {
    "./anims/crouch_shoot_shieldgun_blend_00"
    "./anims/crouch_shoot_shieldgun_blend_01"
    "./anims/crouch_shoot_shieldgun_blend_02"
    "./anims/crouch_shoot_shieldgun_blend_03"
    "./anims/crouch_shoot_shieldgun_blend_04"
    "./anims/crouch_shoot_shieldgun_blend_05"
    "./anims/crouch_shoot_shieldgun_blend_06"
    "./anims/crouch_shoot_shieldgun_blend_07"
    "./anims/crouch_shoot_shieldgun_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "10" }
}
$sequence crouch_reload_shieldgun "./anims/crouch_reload_shieldgun" fps 30
$sequence ref_aim_shieldgun {
    "./anims/ref_aim_shieldgun_blend_00"
    "./anims/ref_aim_shieldgun_blend_01"
    "./anims/ref_aim_shieldgun_blend_02"
    "./anims/ref_aim_shieldgun_blend_03"
    "./anims/ref_aim_shieldgun_blend_04"
    "./anims/ref_aim_shieldgun_blend_05"
    "./anims/ref_aim_shieldgun_blend_06"
    "./anims/ref_aim_shieldgun_blend_07"
    "./anims/ref_aim_shieldgun_blend_08"
    fps 30
    loop
    blend XR -90 90
}
$sequence ref_shoot_shieldgun {
    "./anims/ref_shoot_shieldgun_blend_00"
    "./anims/ref_shoot_shieldgun_blend_01"
    "./anims/ref_shoot_shieldgun_blend_02"
    "./anims/ref_shoot_shieldgun_blend_03"
    "./anims/ref_shoot_shieldgun_blend_04"
    "./anims/ref_shoot_shieldgun_blend_05"
    "./anims/ref_shoot_shieldgun_blend_06"
    "./anims/ref_shoot_shieldgun_blend_07"
    "./anims/ref_shoot_shieldgun_blend_08"
    fps 30
    blend XR -90 90
    { event 5001 0 "10" }
}
$sequence ref_reload_shieldgun "./anims/ref_reload_shieldgun" fps 30
$sequence crouch_aim_shielded {
    "./anims/crouch_aim_shielded_blend_00"
    "./anims/crouch_aim_shielded_blend_01"
    "./anims/crouch_aim_shielded_blend_02"
    "./anims/crouch_aim_shielded_blend_03"
    "./anims/crouch_aim_shielded_blend_04"
    "./anims/crouch_aim_shielded_blend_05"
    "./anims/crouch_aim_shielded_blend_06"
    "./anims/crouch_aim_shielded_blend_07"
    "./anims/crouch_aim_shielded_blend_08"
    fps 20
    loop
    blend XR -90 90
}
$sequence ref_aim_shielded {
    "./anims/ref_aim_shielded_blend_00"
    "./anims/ref_aim_shielded_blend_01"
    "./anims/ref_aim_shielded_blend_02"
    "./anims/ref_aim_shielded_blend_03"
    "./anims/ref_aim_shielded_blend_04"
    "./anims/ref_aim_shielded_blend_05"
    "./anims/ref_aim_shielded_blend_06"
    "./anims/ref_aim_shielded_blend_07"
    "./anims/ref_aim_shielded_blend_08"
    fps 20
    loop
    blend XR -90 90
}
$sequence gut_flinch {
    "./anims/gut_flinch_blend_00"
    "./anims/gut_flinch_blend_01"
    "./anims/gut_flinch_blend_02"
    "./anims/gut_flinch_blend_03"
    "./anims/gut_flinch_blend_04"
    "./anims/gut_flinch_blend_05"
    "./anims/gut_flinch_blend_06"
    "./anims/gut_flinch_blend_07"
    "./anims/gut_flinch_blend_08"
    fps 30
    blend XR -90 90
}
$sequence head_flinch {
    "./anims/head_flinch_blend_00"
    "./anims/head_flinch_blend_01"
    "./anims/head_flinch_blend_02"
    "./anims/head_flinch_blend_03"
    "./anims/head_flinch_blend_04"
    "./anims/head_flinch_blend_05"
    "./anims/head_flinch_blend_06"
    "./anims/head_flinch_blend_07"
    "./anims/head_flinch_blend_08"
    fps 30
    blend XR -90 90
}
$sequence death1 {
    "./anims/death1"
    fps 30
    ACT_DIE_CHESTSHOT 1
    { event 2001 1 "" }
}
$sequence death2 {
    "./anims/death2"
    fps 30
    ACT_DIESIMPLE 2
    { event 2001 1 "" }
}
$sequence death3 {
    "./anims/death3"
    fps 30
    ACT_DIE_BACKSHOT 1
    { event 2001 1 "" }
}
$sequence head {
    "./anims/head"
    fps 30
    ACT_DIE_HEADSHOT 1
    { event 2001 1 "" }
}
$sequence gutshot {
    "./anims/gutshot"
    fps 30
    ACT_DIE_GUTSHOT 1
    { event 2001 1 "" }
}
$sequence left {
    "./anims/left"
    fps 30
    ACT_DIESIMPLE 1
    { event 2001 1 "" }
}
$sequence back {
    "./anims/back"
    fps 30
    ACT_DIEBACKWARD 1
    { event 2001 1 "" }
}
$sequence right {
    "./anims/right"
    fps 30
    ACT_DIESIMPLE 1
    { event 2001 1 "" }
}
$sequence forward {
    "./anims/forward"
    fps 30
    ACT_DIEFORWARD 1
    { event 2001 1 "" }
}
$sequence crouch_die {
    "./anims/crouch_die"
    fps 30
    { event 2001 1 "" }
}
