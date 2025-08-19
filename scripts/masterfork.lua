-- make all large creatures into powers and apply fear auras
btc1_tweaks.titan_worship=function(lines,options,add_to_body,add_to_body_unique,add_tweak_candidate)
	if options.body_size>=500000 and options.body_size<900000 then -- described as "very large", graphics size cutoff
		lines[#lines+1]="[APPLY_CREATURE_VARIATION:AURA_TERROR]" then
		options.can_learn=true -- for flavor text
		lines[#lines+1]="[INTELLIGENT]"
		lines[#lines+1]="[SUPERNATURAL]" -- knows secrets according to their spheres
		lines[#lines+1]="[POWER]" -- impersonates deities
		lines[#lines+1]="[SPREAD_EVIL_SPHERES_IF_RULER]"
	elseif options.body_size>=900000 then
		lines[#lines+1]="[APPLY_CREATURE_VARIATION:AURA_HORROR]" then
		options.can_learn=true -- for flavor text
		lines[#lines+1]="[INTELLIGENT]"
		lines[#lines+1]="[SUPERNATURAL]" -- knows secrets according to their spheres
		lines[#lines+1]="[POWER]" -- impersonates deities
		lines[#lines+1]="[SPREAD_EVIL_SPHERES_IF_RULER]"
	end
end
-- adamantine alloys
preprocess.adamantine_alloys=function()
    if not random_object_parameters.main_world_randoms then return end
    local l=get_debug_logger(2)
    local lines={}
    local reaction_lines={}
    local reaction_names={}
    local adamantine=world.inorganic.inorganic.ADAMANTINE
    if not adamantine then return end
    local adamantine_color=world.descriptor.color[world.descriptor.color_pattern[adamantine.material.color_pattern.SOLID].color[1]]
    local adamantine_modulus = 2500000  --mildly arbitrary, just below the theoretical limit
    l("Starting")
    local done_category=false
    for k,v in ipairs(world.inorganic.inorganic) do
        if not v.flags.SPECIAL and v.material.flags.IS_METAL then
            l(v.token)
            local token="GEN_ADAMANTINE_"..v.token
            lines[#lines+1]="[INORGANIC:"..token.."]"
            add_generated_info(lines)
            lines[#lines+1]="[USE_MATERIAL_TEMPLATE:METAL_TEMPLATE]"
            for kk,vv in pairs(v.material.adj) do
                lines[#lines+1]="[STATE_ADJ:"..kk..":adamantine "..vv.."]" --"adamantine molten steel"? it's fine
            end
            for kk,vv in pairs(v.material.name) do
                lines[#lines+1]="[STATE_NAME:"..kk..":adamantine "..vv.."]"
            end
            l(2)
            local mat_values={}
            -- Find the ratio for which you get closest to (but not below) 2000000 in the material's worst property
            local worst=math.min(v.material.yield.IMPACT,v.material.fracture.SHEAR)
            local wafers=1
            local bars=1
            if worst < 2000000 then
                local ratio = (2000000-3*worst)/1000000
                local best_diff=1
                for i=1,10 do
                    local wafer_amt=i*ratio
                    if wafer_amt>1 and wafer_amt<20 and math.ceil(wafer_amt)-wafer_amt<best_diff then
                        best_diff=math.ceil(wafer_amt)-wafer_amt
                        wafers=math.ceil(wafer_amt)
                        bars=i
                    end
                end
            end
            local avg_denom=1/(bars*3+wafers) -- Multiplication just a bit faster than division, we're rounding at the end anyway
            local solid_cl=nil
            for kk,vv in pairs(v.material.color_pattern) do
                -- time to get silly
                local this_color=world.descriptor.color[world.descriptor.color_pattern[vv].color[1]]
                local wanted_color={
                    r=(this_color.r*bars*3+adamantine_color.r*wafers)*avg_denom,
                    g=(this_color.g*bars*3+adamantine_color.g*wafers)*avg_denom,
                    b=(this_color.b*bars*3+adamantine_color.b*wafers)*avg_denom,
                }
                local best_total_diff=1000000000
                local best_clp=nil
                for _,clp in ipairs(world.descriptor.color_pattern) do
                    if clp.pattern=="MONOTONE" then
                        local cl=world.descriptor.color[clp.color[1]]
                        local diff=math.abs(wanted_color.r-cl.r)+math.abs(wanted_color.b-cl.b)+math.abs(wanted_color.g-cl.g)
                        if diff<best_total_diff then
                            best_clp=clp
                            best_total_diff=diff
                        end
                    end
                end
                lines[#lines+1]="[STATE_COLOR:"..kk..":"..best_clp.token.."]"
                if kk=="SOLID" then solid_cl=world.descriptor.color[best_clp.color[1]] end
            end
            local color_str=solid_cl.col_f..":0:"..solid_cl.col_br
            l(color_str)
            lines[#lines+1]="[DISPLAY_COLOR:"..color_str.."]"
            lines[#lines+1]="[BUILD_COLOR:"..color_str.."]"
            lines[#lines+1]="[ITEMS_METAL][ITEMS_HARD][ITEMS_SCALED][ITEMS_BARRED]"
            lines[#lines+1]="[SPECIAL]"
            if v.material.flags.ITEMS_DIGGER then
                lines[#lines+1]="[ITEMS_DIGGER]"
            end
            local function new_value(str)
                mat_values[str]=mat_values[str] or math.floor((adamantine.material[str]*wafers+v.material[str]*bars*3)*avg_denom+0.5)
                l(str,mat_values[str])
                return mat_values[str]
            end
            local function new_value_nested(str1,str2)
                mat_values[str1..str2]=mat_values[str1..str2] or math.floor((adamantine.material[str1][str2]*wafers+v.material[str1][str2]*bars*3)/(bars*3+wafers)+0.5)
                l(str1..str2,mat_values[str1..str2])
                return mat_values[str1..str2]
            end
            if new_value_nested("fracture","SHEAR")>170000 or new_value_nested("yield","IMPACT")>245000 then
                lines[#lines+1]="[ITEMS_WEAPON][ITEMS_AMMO]"
                if new_value("solid_density")<10000 then
                    lines[#lines+1]="[ITEMS_WEAPON_RANGED][ITEMS_ARMOR]"
                end
            end
            lines[#lines+1]="[MATERIAL_VALUE:"..new_value("base_value").."]"
            lines[#lines+1]="[SPEC_HEAT:"..new_value("temp_spec_heat").."]"
            lines[#lines+1]="[MELTING_POINT:"..new_value("temp_melting_point").."]"
            lines[#lines+1]="[BOILING_POINT:"..new_value("temp_boiling_point").."]"
            lines[#lines+1]="[SOLID_DENSITY:"..new_value("solid_density").."]"
            lines[#lines+1]="[LIQUID_DENSITY:"..new_value("liquid_density").."]"
            lines[#lines+1]="[MOLAR_MASS:"..new_value("molar_mass").."]" -- i don't think this is actually correct
            for _,thing in ipairs({"yield","fracture"}) do
                for force,_ in pairs(v.material[thing]) do
                    lines[#lines+1]="["..string.upper(force).."_"..string.upper(thing)..":"..new_value_nested(thing,force).."]"
                end
            end
            for _,force in ipairs("IMPACT","COMPRESSIVE","TENSILE","TORSION","SHEAR","BENDING") do
                local modulus = v.yield[force] / v.elasticity[force]
                local average_modulus = (adamantine_modulus*wafers + modulus*bars*3)*avg_denom
                local strain_at_yield = math.floor(new_value_nested("yield",force) / average_modulus + 0.5) -- usually zero, but can be 1 or 2 sometimes
                lines[#lines+1]="["..string.upper(force).."_YIELD:"..new_value_nested("yield",force).."]"
                lines[#lines+1]="["..string.upper(force).."_FRACTURE:"..new_value_nested("fracture",force).."]"
                lines[#lines+1]="["..string.upper(force).."_STRAIN_AT_YIELD:"..strain_at_yield.."]"
            end
            lines[#lines+1]="[MAX_EDGE:"..new_value("max_edge").."]"
            local reaction_token=token.."_MAKING"
            reaction_lines[#reaction_lines+1]="[REACTION:"..reaction_token.."]"
            add_generated_info(reaction_lines)
            reaction_lines[#reaction_lines+1]="[NAME:make adamantine "..v.material.name.SOLID.." (use bars)]"
            reaction_lines[#reaction_lines+1]="[BUILDING:BLAST_FURNACE_CHP:NONE]"
            reaction_lines[#reaction_lines+1]="[REAGENT:A:"..tostring(150*wafers)..":BAR:NO_SUBTYPE:METAL:ADAMANTINE]"
            reaction_lines[#reaction_lines+1]="[REAGENT:B:"..tostring(150*bars)..":BAR:NO_SUBTYPE:METAL:"..v.token.."]"
            reaction_lines[#reaction_lines+1]="[PRODUCT:100:"..tostring(bars+wafers)..":BAR:NO_SUBTYPE:METAL:"..token.."][PRODUCT_DIMENSION:150]"
            reaction_lines[#reaction_lines+1]="[FORTRESS_MODE_ENABLED]"
            reaction_lines[#reaction_lines+1]="[CATEGORY:ADAMANTINE_ALLOYS]"
            if not done_category then
                done_category=true
                reaction_lines[#reaction_lines+1]="[CATEGORY_NAME:Adamantine alloys]"
                reaction_lines[#reaction_lines+1]="[CATEGORY_DESCRIPTION:Debase adamantine with other metals to get extremely strong alloys.]"
                reaction_lines[#reaction_lines+1]="[CATEGORY_KEY:CUSTOM_SHIFT_A]"
            end
            reaction_lines[#reaction_lines+1]="[FUEL]"
            reaction_lines[#reaction_lines+1]="[SKILL:SMELT]"
        end
    end
    local entity_lines={}
    raws.register_inorganics(lines)
    -- not used in vanilla right now, due to lack of instruments, but you CAN do this
    raws.register_reactions(reaction_lines)
end
-- randomly generated elementals
fb_elements = {
	{
		name="fire",
		rcm="FLAME",
		spheres={ FIRE=true },
		options={ fire_immune=true }
	},
	{
		name="earth",
		rcm="ANY_MINERAL",
		rcp_options={ always_flightless=true },
		spheres={
			EARTH=true,
			MINERALS=true
		}
	},
	{
		name="air",
		rcm="STEAM",
		spheres={
			WIND=true,
			SKY=true
		},
		options={
			always_insubstantial=true,
			intangible_flier=true
		}
	}
}
creatures.fb.elemental=function(layer_type,tok)
	local lines={}
	local options={
		strong_attack_tweak=true,
		always_make_uniform=true, --irrelevant due to sphere_rcm
		spheres={},
		sickness_name="dyskrasia",
		token=tok
	}
	lines=split_to_lines(lines,[[
		[FEATURE_BEAST]
		[ATTACK_TRIGGER:0:0:2]
		[NO_GENDER]
		[NO_EAT][NO_DRINK]
		[DIFFICULTY:10]
		
		[NATURAL_SKILL:WRESTLING:6]
		[NATURAL_SKILL:BITE:6]
		[NATURAL_SKILL:GRASP_STRIKE:6]
		[NATURAL_SKILL:STANCE_STRIKE:6]
		[NATURAL_SKILL:MELEE_COMBAT:6]
		[NATURAL_SKILL:DODGING:6]
		[NATURAL_SKILL:SITUATIONAL_AWARENESS:6]
		[LARGE_PREDATOR]
	]])
	
	-- Create a water elemental in water layers, otherwise use another type
	local water_elemental = {
		name="water",
		rcm="WATER",
		spheres={WATER=true},
		options={do_water=true}
	}
	local my_element = layer_type==1 and pick_random(fb_elements) or water_elemental
	
	-- Assign propertes from chosen element
	map_merge(options.spheres,my_element.spheres)
	if my_element.options then map_merge(options,my_element.options) end
	
	add_regular_tokens(lines,options)
	lines[#lines+1]=layer_type==0 and "[BIOME:SUBTERRANEAN_WATER]" or "[BIOME:SUBTERRANEAN_CHASM]"
	populate_sphere_info(lines,options)
	
	-- Set custom material
	options.sphere_rcm=my_element.rcm
	-- Build body
	local rcp=get_random_creature_profile(options)
	-- Set more options on the RCP
	if my_element.rcp_options then map_merge(rcp.options,my_element.rcp_options) end
	add_body_size(lines,math.max(10000000,rcp.min_size),options)
	lines[#lines+1]="[CREATURE_TILE:'E']"
	build_procgen_creature(rcp,lines,options)
	
	-- Generate name
	local element_name = my_element.name or "glitchstuff"
	local name_str = element_name.." elemental:"..element_name.." elemental:"..element_name.."-elemental]"
	lines[#lines+1]="[GO_TO_START]"
	lines[#lines+1]="[NAME:"..name_str
	lines[#lines+1]="[CASTE_NAME:"..name_str
	
	return {raws=lines,weight=1.5}
end
-- new generated forgotten beasts
creatures.fb.unbidden=function(layer_type,tok)
    if layer_type==0 then return nil end -- land only
    local tbl={}
    local options={
        strong_attack_tweak=true,
        always_make_uniform=true,
        always_insubstantial=true,
        intangible_flier=true,
        spheres={CAVERNS=true},
        is_evil=true,
        sickness_name="beast sickness",
        token=tok
    }
    tbl=split_to_lines(tbl,[[
    [FEATURE_BEAST]
    [ATTACK_TRIGGER:0:0:2]
    [NAME:unbidden spirit:unbidden spirit:unbidden spirit]
    [CASTE_NAME:unbidden spirit:unbidden spirit:unbidden spirit]
    [NO_GENDER]
    [CARNIVORE]
    [DIFFICULTY:10]

    [NATURAL_SKILL:WRESTLING:6]
    [NATURAL_SKILL:BITE:6]
    [NATURAL_SKILL:GRASP_STRIKE:6]
    [NATURAL_SKILL:STANCE_STRIKE:6]
    [NATURAL_SKILL:MELEE_COMBAT:6]
    [NATURAL_SKILL:DODGING:6]
    [NATURAL_SKILL:SITUATIONAL_AWARENESS:6]
    [LARGE_PREDATOR]
    ]])
    add_regular_tokens(tbl,options)
    tbl[#tbl+1]=layer_type==0 and "[BIOME:SUBTERRANEAN_WATER]" or "[BIOME:SUBTERRANEAN_CHASM]"
    if layer_type==0 then options.spheres.WATER=true end
    options.spheres[pick_random(evil_spheres)]=true
    options.do_water=layer_type==0
    populate_sphere_info(tbl,options)
    local rcp=get_random_creature_profile(options)
    add_body_size(tbl,math.max(10000000,rcp.min_size),options)
    tbl[#tbl+1]="[CREATURE_TILE:"..tile_string(rcp.tile).."]"
    build_procgen_creature(rcp,tbl,options)
    -- Weight is a float; all vanilla objects have weight 1
    return {creature=tbl,weight=0.5}
end