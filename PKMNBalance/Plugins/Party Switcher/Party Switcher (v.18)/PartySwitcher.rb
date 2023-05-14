#==============================================================================#
#                         Party Switcher (Based on Reborn's code)              #
#                                                                              #
#==============================================================================#
PluginManager.register({
    :name => "Party Switcher",
    :version => "2.0",
    :credits => "Michael, TechSkylander1518, Marcello, ZeroKid",
    :link => "https://reliccastle.com/resources/323/"
  })
  
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
  #Allows for the storing and switching of mons
  #--------------------------------------------------------------------------------
  module PokeBattle_BattleCommon
    def pbStorePokemon(pokemon)
      if !(pokemon.isShadow? rescue false)
        if pbDisplayConfirm(_INTL("Would you like to give a nickname to {1}?",pokemon.name))
          species=PBSpecies.getName(pokemon.species)
          nickname=@scene.pbNameEntry(_INTL("{1}'s nickname?",species),pokemon)
          pokemon.name=nickname if nickname!=""
        end
      end
      if $Trainer.party.length<6
        $Trainer.party[$Trainer.party.length]=pokemon
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
                 if eggcount<=1 && !($Trainer.party[iMon].isEgg?) && pokemon.isEgg?
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
                $Trainer.party[iMon] = pokemon
                @initialItems[0][iMon] = pokemon.item_id if @initialItems
                $Trainer.party.compact!
                return -1
              else
                pbMessage("No space left in the PC.")
                return false
              end
            end      
          else
            monsent=true
            pokemon.heal
            oldcurbox=$PokemonStorage.currentBox
            storedbox=$PokemonStorage.pbStoreCaught(pokemon)
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
   
  def pbStorePokemon(pokemon)
    if pbBoxesFull?
      pbMessage(_INTL("There's no more room for Pokémon!\1"))
      pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
      return
    end
    pokemon.pbRecordFirstMoves
    if $Trainer.party.length<6
      $Trainer.party[$Trainer.party.length]=pokemon
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
              if eggcount<=1 && !($Trainer.party[iMon].isEgg?) && pokemon.isEgg?
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
              $Trainer.party[iMon] = pokemon
            else
              pbMessage("No space left in the PC.")
              return false
            end
          end      
        else
          monsent=true
          oldcurbox=$PokemonStorage.currentBox
          storedbox=$PokemonStorage.pbStoreCaught(pokemon)
          curboxname=$PokemonStorage[oldcurbox].name
          boxname=$PokemonStorage[storedbox].name
          creator=nil
          creator=pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
          if storedbox!=oldcurbox
            if creator
              pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1",curboxname,creator))
            else
              pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1",curboxname))
            end
            pbMessage(_INTL("{1} was transferred to box \"{2}.\"",pokemon.name,boxname))
          else
            if creator
              pbMessage(_INTL("{1} was transferred to {2}'s PC.\1",pokemon.name,creator))
            else
              pbMessage(_INTL("{1} was transferred to someone's PC.\1",pokemon.name))
            end
            pbMessage(_INTL("It was stored in box \"{1}\".",boxname))
          end
        end    
      end
    end
  end
   
  def pbAddPokemonSilent(pokemon,level=nil,seeform=true)
    return false if !pokemon || pbBoxesFull? || !$Trainer
    if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
      pokemon=getID(PBSpecies,pokemon)
    end
    if pokemon.is_a?(Integer) && level.is_a?(Integer)
      pokemon=PokeBattle_Pokemon.new(pokemon,level,$Trainer)
    end
    if pokemon.ot == ""
      pokemon.ot = $Trainer.name 
      pokemon.trainerID = $Trainer.id
    end  
    $Trainer.seen[pokemon.species]=true
    $Trainer.owned[pokemon.species]=true
    pbSeenForm(pokemon) if seeform
    pokemon.pbRecordFirstMoves
    if $Trainer.party.length<6
      $Trainer.party[$Trainer.party.length]=pokemon
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
              if eggcount<=1 && !($Trainer.party[iMon].isEgg?) && pokemon.isEgg?
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
              pbMessage(_INTL("{1} was sent to {2}.", $Trainer.party[iMon].name, $PokemonStorage[iBox].name))
              $Trainer.party[iMon] = pokemon
            else
              pbMessage("No space left in the PC.")
              return false
            end
          end      
        else
          monsent=true
          storedbox = $PokemonStorage.pbStoreCaught(pokemon)
          if pokemon.isEgg?
           oldcurbox=$PokemonStorage.currentBox
           #storedbox=$PokemonStorage.pbStoreCaught(pokemon)
           curboxname=$PokemonStorage[oldcurbox].name
           boxname=$PokemonStorage[storedbox].name
           creator=nil
           creator=pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
            if storedbox!=oldcurbox
              if creator
                pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1",curboxname,creator))
              else
                pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1",curboxname))
              end
              pbMessage(_INTL("{1} was transferred to box \"{2}.\"",pokemon.name,boxname))
            else
              if creator
                pbMessage(_INTL("{1} was transferred to {2}'s PC.\1",pokemon.name,creator))
              else
                pbMessage(_INTL("{1} was transferred to someone's PC.\1",pokemon.name))
              end
              pbMessage(_INTL("It was stored in box \"{1}\".",boxname))
            end
          end
        end
      end    
    end
    return true
  end
   
  
  def pbAddForeignPokemon(pokemon,level=nil,ownerName=nil,nickname=nil,ownerGender=0,seeform=true)
    return false if !pokemon || pbBoxesFull? || !$Trainer
    pokemon = getID(PBSpecies,pokemon)
    if pokemon.is_a?(Integer) && level.is_a?(Integer)
      pokemon = pbNewPkmn(pokemon,level)
    end
    # Set original trainer to a foreign one (if ID isn't already foreign)
    if pokemon.trainerID==$Trainer.id
      pokemon.trainerID = $Trainer.getForeignID
      pokemon.ot        = ownerName if ownerName && ownerName!=""
      pokemon.otgender  = ownerGender
    end
    # Set nickname
    pokemon.name = nickname[0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE] if nickname && nickname!=""
    # Recalculate stats
    pokemon.calcStats
    if ownerName
      pbMessage(_INTL("\\me[Pkmn get]{1} received a Pokémon from {2}.\1",$Trainer.name,ownerName))
    else
      pbMessage(_INTL("\\me[Pkmn get]{1} received a Pokémon.\1",$Trainer.name))
    end
    pbStorePokemon(pokemon)
    $Trainer.seen[pokemon.species]  = true
    $Trainer.owned[pokemon.species] = true
    pbSeenForm(pokemon) if seeform
    return true
  end
  
  def pbGenerateEgg(pokemon,text="")
    return false if !pokemon || pbBoxesFull? || !$Trainer
    pokemon = getID(PBSpecies,pokemon)
    if pokemon.is_a?(Integer)
      pokemon = pbNewPkmn(pokemon,EGG_LEVEL)
    end
    # Get egg steps
    eggSteps = pbGetSpeciesData(pokemon.species,pokemon.form,SpeciesStepsToHatch)
    # Set egg's details
    pokemon.name       = _INTL("Egg")
    pokemon.eggsteps   = eggSteps
    pokemon.obtainText = text
    pokemon.calcStats
    # Add egg to party
    if pbBoxesFull?
      pbMessage(_INTL("There's no more room for Pokémon!\1"))
      pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
      return
    end
    if $Trainer.party.length<6
      $Trainer.party[$Trainer.party.length]=pokemon
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
              if eggcount<=1 && !($Trainer.party[iMon].isEgg?) && pokemon.isEgg?
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
              $Trainer.party[iMon] = pokemon
            else
              pbMessage("No space left in the PC.")
              return false
            end
          end      
        else
          monsent=true
          oldcurbox=$PokemonStorage.currentBox
          storedbox=$PokemonStorage.pbStoreCaught(pokemon)
          curboxname=$PokemonStorage[oldcurbox].name
          boxname=$PokemonStorage[storedbox].name
          creator=nil
          creator=pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
          if storedbox!=oldcurbox
            if creator
              pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1",curboxname,creator))
            else
              pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1",curboxname))
            end
            pbMessage(_INTL("{1} was transferred to box \"{2}.\"",pokemon.name,boxname))
          else
            if creator
              pbMessage(_INTL("{1} was transferred to {2}'s PC.\1",pokemon.name,creator))
            else
              pbMessage(_INTL("{1} was transferred to someone's PC.\1",pokemon.name))
            end
            pbMessage(_INTL("It was stored in box \"{1}\".",boxname))
          end
        end    
      end
    end
  end
  alias pbAddEgg pbGenerateEgg
  alias pbGenEgg pbGenerateEgg
  
  
  
  
  #--------------------------------------------------------------------------------
  #Provides Evolution Check on Party Switcher
  #--------------------------------------------------------------------------------
  class PokemonTemp
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
   
  def pbEvolutionCheck(currentlevels)
    for i in 0...currentlevels.length
      pokemon = $Trainer.party[i]
      next if $PokemonTemp.party[i] != $Trainer.party[i] # changed added to fix party swap evo bug
      next if pokemon.hp==0 && !NEWEST_BATTLE_MECHANICS
      if pokemon && (!currentlevels[i] || pokemon.level!=currentlevels[i])
        newspecies = pbCheckEvolution(pokemon)
        if newspecies>0
          evo = PokemonEvolutionScene.new
          evo.pbStartScreen(pokemon,newspecies)
          evo.pbEvolution
          evo.pbEndScreen
        end
      end
    end
  end