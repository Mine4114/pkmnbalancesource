#==============================================================================#
#                         Party Switcher (Based on Reborn's code)              #
#                                                                              #
#==============================================================================#

module PartySwitcher
  # Variable that enables the player to see the summary menu when choosing a Pokemon to switch  
  SUMMARY_MENU = true
end

#--------------------------------------------------------------------------------
#Allows one to see summary when choosing a Pokemon in party menu
#--------------------------------------------------------------------------------
class PokemonPartyScreen

  def pbChoosePokemonSummary
    ret = -1
    loop do
      @scene.pbSetHelpText(_INTL("Choose a Pokémon.")) 
      pkmnid = @scene.pbChoosePokemon
      break if pkmnid<0   # Cancelled
      cmdChoose   = -1
      cmdSummary = -1
      commands = []
      commands[cmdChoose = commands.length]   = _INTL("Choose")
      pkmn = @party[pkmnid]
      commands[cmdSummary = commands.length]   = _INTL("Summary")
      commands[commands.length]                = _INTL("Cancel")
      command = @scene.pbShowCommands(_INTL("Do what with {1}?",pkmn.name),commands) if pkmn
      if cmdChoose>=0 && command==cmdChoose
        ret = pkmnid
        break
      elsif cmdSummary>=0 && command==cmdSummary
        @scene.pbSummary(pkmnid) {
          @scene.pbSetHelpText(_INTL("Choose a Pokémon."))
        }
      end
    end
    return ret
  end
end

#--------------------------------------------------------------------------------
#Allows for the storing and switching of Pokemon in battle
#--------------------------------------------------------------------------------
module PokeBattle_BattleCommon
  def pbStorePokemon(pkmn)
    # Nickname the Pokémon (unless it's a Shadow Pokémon)
    if !pkmn.shadowPokemon?
      if pbDisplayConfirm(_INTL("Would you like to give a nickname to {1}?", pkmn.name))
        nickname = @scene.pbNameEntry(_INTL("{1}'s nickname?", pkmn.speciesName), pkmn)
        pkmn.name = nickname
      end
    end
    if $Trainer.party.length<6
      $Trainer.party[$Trainer.party.length]=pkmn
      return -1
    else
      monsent=false
      while !monsent
        if pbConfirmMessageSerious(_INTL("The party is full; do you want to send someone to the PC?"))
          iMon = -2 
          eggcount = 0
          for i in $Trainer.party
            next if i.isEgg?
            eggcount += 1
          end
          pbFadeOutIn(99999){
            sscene  = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
            sscreen.pbStartScene(_INTL("Choose a Pokémon."),false)
            loop do
               PartySwitcher::SUMMARY_MENU ? iMon=sscreen.pbChoosePokemonSummary : iMon=sscreen.pbChoosePokemon
               if eggcount<=1 && !($Trainer.party[iMon].isEgg?) && pkmn.isEgg?
                pbMessage("That's your last Pokémon!")              
              else
                sscreen.pbEndScene
                break
              end
            end
          }
          if !(iMon < 0)
            iBox = $PokemonStorage.pbStoreCaught($Trainer.party[iMon])
            if iBox >= 0
              monsent=true
              $Trainer.party[iMon].heal
              pbMessage(_INTL("{1} was sent to {2}.", $Trainer.party[iMon].name, $PokemonStorage[iBox].name))
              $Trainer.party[iMon] = pkmn
              @initialItems[0][iMon] = pkmn.item_id if @initialItems
              $Trainer.party.compact!
              return -1
            else
              pbMessage("No space left in the PC.")
              return false
            end
          end      
        else
          monsent=true
          pkmn.heal
          oldcurbox=$PokemonStorage.currentBox
          storedbox=$PokemonStorage.pbStoreCaught(pkmn)
          if storedbox<0
            pbDisplayPaused(_INTL("Can't catch any more..."))
            return oldcurbox
          else
            return storedbox
          end
        end
      end      
    end
  end
end  

#--------------------------------------------------------------------------------
#Allows for the storing and switching of Pokemon outside of battle
#--------------------------------------------------------------------------------
def pbStorePokemon(pkmn)
  if pbBoxesFull?
    pbMessage(_INTL("There's no more room for Pokémon!\1"))
    pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
    return
  end
  pkmn.record_first_moves
  if $Trainer.party_full?
    monsent=false
    while !monsent
      if pbConfirmMessageSerious(_INTL("The party is full; do you want to send someone to the PC?"))
        iMon = -2 
        eggcount = 0
        for i in $Trainer.party
          next if i.isEgg?
          eggcount += 1
        end
        pbFadeOutIn(99999){
          sscene  = PokemonParty_Scene.new
          sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
          sscreen.pbStartScene(_INTL("Choose a Pokémon."),false)
          loop do
            sscene.pbSetHelpText(_INTL("Choose a Pokémon."))
            PartySwitcher::SUMMARY_MENU ? iMon=sscreen.pbChoosePokemonSummary : iMon=sscreen.pbChoosePokemon
            if eggcount<=1 && !($Trainer.party[iMon].isEgg?) && pkmn.isEgg?
              pbMessage("That's your last Pokémon!")              
            else
              sscreen.pbEndScene
              break
            end
          end
        }
        if !(iMon < 0)    
          iBox = $PokemonStorage.pbStoreCaught($Trainer.party[iMon])
          if iBox >= 0
            monsent=true
            $Trainer.party[iMon].heal
            pbMessage(_INTL("{1} was sent to {2}.", $Trainer.party[iMon].name, $PokemonStorage[iBox].name))
            $Trainer.party[iMon] = pkmn
          else
            pbMessage("No space left in the PC.")
            return false
          end
        end
      else
        monsent=true
        oldcurbox = $PokemonStorage.currentBox
        storedbox = $PokemonStorage.pbStoreCaught(pkmn)
        curboxname = $PokemonStorage[oldcurbox].name
        boxname = $PokemonStorage[storedbox].name
        creator = nil
        creator = pbGetStorageCreator if $Trainer.seen_storage_creator
        if storedbox != oldcurbox
          if creator
            pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1", curboxname, creator))
          else
            pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1", curboxname))
          end
          pbMessage(_INTL("{1} was transferred to box \"{2}.\"", pkmn.name, boxname))
        else
          if creator
            pbMessage(_INTL("{1} was transferred to {2}'s PC.\1", pkmn.name, creator))
          else
            pbMessage(_INTL("{1} was transferred to someone's PC.\1", pkmn.name))
          end
          pbMessage(_INTL("It was stored in box \"{1}.\"", boxname))
        end
      end
    end
  else
    $Trainer.party[$Trainer.party.length] = pkmn
  end
end
 
def pbAddPokemonSilent(pkmn, level = 1, see_form = true)
  return false if !pkmn || pbBoxesFull?
  pkmn = Pokemon.new(pkmn, level) if !pkmn.is_a?(Pokemon)
  $Trainer.pokedex.register(pkmn) if see_form
  $Trainer.pokedex.set_owned(pkmn.species)
  pkmn.record_first_moves
  if $Trainer.party_full?
    monsent=false
    while !monsent
      if pbConfirmMessageSerious(_INTL("The party is full; do you want to send someone to the PC?"))
        iMon = -2 
        eggcount = 0
        for i in $Trainer.party
          next if i.isEgg?
          eggcount += 1
        end
        pbFadeOutIn(99999){
          sscene  = PokemonParty_Scene.new
          sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
          sscreen.pbStartScene(_INTL("Choose a Pokémon."),false)
          loop do
            sscene.pbSetHelpText(_INTL("Choose a Pokémon."))
            PartySwitcher::SUMMARY_MENU ? iMon=sscreen.pbChoosePokemonSummary : iMon=sscreen.pbChoosePokemon
            if eggcount<=1 && !($Trainer.party[iMon].isEgg?) && pkmn.isEgg?
              pbMessage("That's your last Pokémon!")              
            else
              sscreen.pbEndScene
              break
            end
          end
        }
        if !(iMon < 0)    
          iBox = $PokemonStorage.pbStoreCaught($Trainer.party[iMon])
          if iBox >= 0
            monsent=true
            $Trainer.party[iMon].heal
            pbMessage(_INTL("{1} was sent to {2}.", $Trainer.party[iMon].name, $PokemonStorage[iBox].name))
            $Trainer.party[iMon] = pkmn
          else
            pbMessage("No space left in the PC.")
            return false
          end
        end
      else
        monsent=true
        oldcurbox = $PokemonStorage.currentBox
        storedbox = $PokemonStorage.pbStoreCaught(pkmn)
        curboxname = $PokemonStorage[oldcurbox].name
        boxname = $PokemonStorage[storedbox].name
        creator = nil
        creator = pbGetStorageCreator if $Trainer.seen_storage_creator
        if storedbox != oldcurbox
          if creator
            pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1", curboxname, creator))
          else
            pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1", curboxname))
          end
          pbMessage(_INTL("{1} was transferred to box \"{2}.\"", pkmn.name, boxname))
        else
          if creator
            pbMessage(_INTL("{1} was transferred to {2}'s PC.\1", pkmn.name, creator))
          else
            pbMessage(_INTL("{1} was transferred to someone's PC.\1", pkmn.name))
          end
          pbMessage(_INTL("It was stored in box \"{1}.\"", boxname))
        end
      end
    end
  else
    $Trainer.party[$Trainer.party.length] = pkmn
  end
  return true
end

def pbAddForeignPokemon(pkmn, level = 1, owner_name = nil, nickname = nil, owner_gender = 0, see_form = true)
  return false if !pkmn || $Trainer.party_full?
  pkmn = Pokemon.new(pkmn, level) if !pkmn.is_a?(Pokemon)
  # Set original trainer to a foreign one
  pkmn.owner = Pokemon::Owner.new_foreign(owner_name || "", owner_gender)
  # Set nickname
  pkmn.name = nickname[0, Pokemon::MAX_NAME_SIZE] if !nil_or_empty?(nickname)
  # Recalculate stats
  pkmn.calc_stats
  if owner_name
    pbMessage(_INTL("\\me[Pkmn get]{1} received a Pokémon from {2}.\1", $Trainer.name, owner_name))
  else
    pbMessage(_INTL("\\me[Pkmn get]{1} received a Pokémon.\1", $Trainer.name))
  end
  pbStorePokemon(pkmn)
  $Trainer.pokedex.register(pkmn) if see_form
  $Trainer.pokedex.set_owned(pkmn.species)
  return true
end
 
def pbGenerateEgg(pkmn, text = "")
  return false if !pkmn || $Trainer.party_full?
  pkmn = Pokemon.new(pkmn, Settings::EGG_LEVEL) if !pkmn.is_a?(Pokemon)
  # Set egg's details
  pkmn.name           = _INTL("Egg")
  pkmn.steps_to_hatch = pkmn.species_data.hatch_steps
  pkmn.obtain_text    = text
  pkmn.calc_stats
  # Add egg to party
  if pbBoxesFull?
    pbMessage(_INTL("There's no more room for Pokémon!\1"))
    pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
    return
  end
  if $Trainer.party_full?
    monsent=false
    while !monsent
      if pbConfirmMessageSerious(_INTL("The party is full; do you want to send someone to the PC?"))
        iMon = -2 
        eggcount = 0
        for i in $Trainer.party
          next if i.isEgg?
          eggcount += 1
        end
        pbFadeOutIn(99999){
          sscene  = PokemonParty_Scene.new
          sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
          sscreen.pbStartScene(_INTL("Choose a Pokémon."),false)
          loop do
            sscene.pbSetHelpText(_INTL("Choose a Pokémon."))
            PartySwitcher::SUMMARY_MENU ? iMon=sscreen.pbChoosePokemonSummary : iMon=sscreen.pbChoosePokemon
            if eggcount<=1 && !($Trainer.party[iMon].isEgg?) && pkmn.isEgg?
              pbMessage("That's your last Pokémon!")              
            else
              sscreen.pbEndScene
              break
            end
          end
        }
        if !(iMon < 0)    
          iBox = $PokemonStorage.pbStoreCaught($Trainer.party[iMon])
          if iBox >= 0
            monsent=true
            $Trainer.party[iMon].heal
            pbMessage(_INTL("{1} was sent to {2}.", $Trainer.party[iMon].name, $PokemonStorage[iBox].name))
            $Trainer.party[iMon] = pkmn
          else
            pbMessage("No space left in the PC.")
            return false
          end
        end
      else
        monsent=true
        oldcurbox = $PokemonStorage.currentBox
        storedbox = $PokemonStorage.pbStoreCaught(pkmn)
        curboxname = $PokemonStorage[oldcurbox].name
        boxname = $PokemonStorage[storedbox].name
        creator = nil
        creator = pbGetStorageCreator if $Trainer.seen_storage_creator
        if storedbox != oldcurbox
          if creator
            pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1", curboxname, creator))
          else
            pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1", curboxname))
          end
          pbMessage(_INTL("{1} was transferred to box \"{2}.\"", pkmn.name, boxname))
        else
          if creator
            pbMessage(_INTL("{1} was transferred to {2}'s PC.\1", pkmn.name, creator))
          else
            pbMessage(_INTL("{1} was transferred to someone's PC.\1", pkmn.name))
          end
          pbMessage(_INTL("It was stored in box \"{1}.\"", boxname))
        end
      end
    end
  else
    $Trainer.party[$Trainer.party.length] = pkmn
  end
end
alias pbAddEgg pbGenerateEgg
alias pbGenEgg pbGenerateEgg
 
#--------------------------------------------------------------------------------
#Provides Evolution Check on Party Switcher
#--------------------------------------------------------------------------------
class PokemonTemp
  attr_accessor :encounterTriggered
  attr_accessor :encounterType 
  attr_accessor :evolutionLevels
  attr_accessor :party # changed added
end
 
Events.onStartBattle+=proc {|sender,e| # Changed added $PokemonTemp.party to fix party swap evo bug
  $PokemonTemp.party = []
  $PokemonTemp.evolutionLevels = []
  for i in 0...$Trainer.party.length
    $PokemonTemp.party[i] = $Trainer.party[i]
    $PokemonTemp.evolutionLevels[i] = $Trainer.party[i].level
  end
}

def pbEvolutionCheck(currentLevels)
  for i in 0...currentLevels.length
    pkmn = $Trainer.party[i]
    next if $PokemonTemp.party[i] != $Trainer.party[i] # changed added to fix party swap evo bug
    next if !pkmn || (pkmn.hp==0 && !Settings::CHECK_EVOLUTION_FOR_FAINTED_POKEMON)
    next if currentLevels[i] && pkmn.level==currentLevels[i]
    newSpecies = pkmn.check_evolution_on_level_up
    next if !newSpecies
    evo = PokemonEvolutionScene.new
    evo.pbStartScreen(pkmn,newSpecies)
    evo.pbEvolution
    evo.pbEndScreen
  end
end
