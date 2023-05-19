% irem nur yıldırım
% 2021400042
% compiling: yes
% complete: yes
distance(0, 0, 0).  % a dummy predicate to make the sim work.
:- consult('simulator.pro').

%these are my own predicates
  


can_perform_portal(UniverseId,TargetUniverseId,TargetTime,StateId,AgentId,TargetStateId):-
    state(StateId, Agents, _, TurnOrder),
    history(StateId, UniverseId, Time, _),
    Agent = Agents.get(AgentId),
            % check whether global universe limit has been reached
            global_universe_id(GlobalUniverseId),
            universe_limit(UniverseLimit),
            GlobalUniverseId < UniverseLimit,
            %mana check
            (Agent.class = wizard -> TravelCost = 2; TravelCost = 5),
            Cost is abs(TargetTime - Time)*TravelCost + abs(TargetUniverseId - UniverseId)*TravelCost,
            Agent.mana >= Cost,
            % agent cannot time travel if there is only one agent in the universe
            length(TurnOrder, NumAgents),
            NumAgents > 1,
            % check whether target is now or in the past
            current_time(TargetUniverseId, TargetUniCurrentTime, _),
            TargetTime < TargetUniCurrentTime,
            % check whether the target location is occupied
            get_earliest_target_state(TargetUniverseId, TargetTime, TargetStateId),
            state(TargetStateId, TargetAgents, _, TargetTurnOrder),
            TargetState = state(TargetStateId, TargetAgents, _, TargetTurnOrder),
            \+tile_occupied(Agent.x, Agent.y, TargetState).

           
           
 can_perform_portal_to_now(UniverseId,TargetUniverseId,StateId,AgentId,TargetStateId):-
         state(StateId, Agents, _, TurnOrder),
         history(StateId, UniverseId, Time, _),
         Agent = Agents.get(AgentId),
            % agent cannot time travel if there is only one agent in the universe
            length(TurnOrder, NumAgents),
            NumAgents > 1,
            % agent can only travel to now if it's the first turn in the target universe
            current_time(TargetUniverseId, TargetTime, 0),
            % agent cannot travel to current universe's now (would be a no-op)
            \+(TargetUniverseId = UniverseId), %actually we do add afterwards in traversable_states
            % check whether there is enough mana
            (Agent.class = wizard -> TravelCost = 2; TravelCost = 5),
            Cost is abs(TargetTime - Time)*TravelCost + abs(TargetUniverseId - UniverseId)*TravelCost,
            Agent.mana >= Cost,
            % check whether the target location is occupied
            get_latest_target_state(TargetUniverseId, TargetTime, TargetStateId),
            state(TargetStateId, TargetAgents, _, TargetTurnOrder),
            TargetState = state(TargetStateId, TargetAgents, _, TargetTurnOrder),
            \+tile_occupied(Agent.x, Agent.y, TargetState).
           
        
        

traversable_states(StateId, AgentId, AllTraversableStates) :-
    get_universe_and_time_for_state(StateId, UniverseId, _),
    % Get all possible target universes and times from history predicate
   % findall((TargetStateId,TargetUniverseId, TargetTime), history(TargetStateId, TargetUniverseId, TargetTime, _), TargetUniverseTimes),
    % Get all states that can be reached via a portal to now action
    findall(TargetStateId, 
        
        can_perform_portal_to_now(UniverseId, TargetUniverseId,StateId,AgentId,TargetStateId)
    , PortalToNowStates),
    % Get all states that can be reached via a portal action, but only if they aren't already in PortalToNowStates
        findall(TargetStateId, (
            can_perform_portal(UniverseId, TargetUniverseId, _,StateId,AgentId,TargetStateId)
         ) , PortalStates),
    
    % Combine the two lists of states into a single list
    append(PortalToNowStates, PortalStates, TraversableStates),
    % Add the current state if the agent is in the universe
    AllTraversableStates = [StateId|TraversableStates].



get_universe_and_time_for_state(StateId, UniverseId, Time) :-
    history(StateId, UniverseId, Time, _). %for a given state i retrieve universe and time


% travel cost based on agent class
%travel_cost(wizard, 2).
%travel_cost(_ , 5).
travel_cost(Class, Cost) :-
    (Class = wizard -> Cost = 2; Cost = 5).




% get_agent_from_id(AgentId, Agent,StateId)
get_agent_from_id(AgentId, Agent,StateId) :-
    % get the current state and agents
    state(StateId, Agents, _, _),
    % retrieve the agent from the ID
     get_dict(AgentId, Agents, Agent).  




%default predicates of the solution


 distance(Agent, TargetAgent, Distance) :-
  DisX is abs(Agent.x - TargetAgent.x),
    DisY is abs(Agent.y - TargetAgent.y),
    Distance is DisX + DisY.





multiverse_distance(StateId, AgentId, TargetStateId, TargetAgentId, Distance):-
% retrieve the relevant information about the agents and states
get_universe_and_time_for_state(StateId,UniverseId1,Time1),
get_universe_and_time_for_state(TargetStateId,UniverseId2,Time2),
get_agent_from_id(AgentId,Agent1,StateId),
get_agent_from_id(TargetAgentId,Agent2,TargetStateId),
    % compute the travel cost based on the agent class

    travel_cost(Agent1.class, TravelCost1),
    format("Agent ~w is a ~w ", [AgentId, Agent1.class]),
    %travel_cost(Agent2.class, TravelCost2),
    % compute the multiverse distance using the formula
    Distance is abs(Agent1.x - Agent2.x) + abs(Agent1.y - Agent2.y) +
        (TravelCost1)*(abs(Time1 - Time2) + abs(UniverseId1 - UniverseId2)),
        format('Distance = abs(~w - ~w) + abs(~w - ~w) + (~w) * (abs(~w - ~w) + abs(~w - ~w))', [Agent1.x, Agent2.x, Agent1.y, Agent2.y, TravelCost1, Time1, Time2, UniverseId1, UniverseId2]).



 nearest_agent(StateId, AgentId, NearestAgentId, Distance):- 
 % get the current state and agents
    state(StateId, Agents, _, _),
get_agent_from_id(AgentId, CurrentAgent, StateId),
% find the distances between the current agent and all other agents in a tuple
findall(D-Id, (get_agent_from_id(Id, Agent, StateId), Id \= AgentId, \+(Agent.name = CurrentAgent.name) ,distance(CurrentAgent, Agent, D)), Distances),
% id is all the possible ids of any agent in the list that doesnt have the same id with the current one
min_member(Distance-NearestAgentId, Distances),
% make sure the nearest agent has a different name than the current agent
get_agent_from_id(NearestAgentId, NearestAgent, StateId).





nearest_agent_in_multiverse(StateId, AgentId, TargetStateId, TargetAgentId, Distance) :-
    % get the current state and agents
    state(StateId, Agents, _, _),
    get_agent_from_id(AgentId, CurrentAgent, StateId),

    % collect all distances between the current agent and all other agents in each state
    findall(
        Distance-CurStateId-Id,
        (
            state(CurStateId, CurAgents, _, _),
          
            get_agent_from_id(Id, Agent, CurStateId),
             CurrentAgent.name \= Agent.name,
            multiverse_distance(StateId, AgentId, CurStateId, Id, Distance)
        ),
        Distances
    ),
    min_member(Distance-NearestStateId-NearestAgentId, Distances),
% make sure the nearest agent has a different name than the current agent
get_agent_from_id(NearestAgentId, NearestAgent, NearestStateId),
     TargetStateId = NearestStateId,
    TargetAgentId = NearestAgentId.
    



    num_agents_in_state(StateId, Name, NumWarriors, NumWizards, NumRogues):-
    % Find all agents in the state
    state(StateId, Agents, _, _),
    %dict_values(AgentsDict, Agents),
    
    % Filter the agents by class and name
    findall(Warrior, (Warrior=Agents.get(AgentId), Warrior.class == warrior, Warrior.name \= Name), Warriors),
    findall(Wizard, (Wizard=Agents.get(AgentId), Wizard.class == wizard, Wizard.name \= Name), Wizards),
    findall(Rogue, (Rogue=Agents.get(AgentId), Rogue.class == rogue, Rogue.name \= Name), Rogues),
    
    % Get the lengths of the filtered lists
    length(Warriors, NumWarriors),
    length(Wizards, NumWizards),
    length(Rogues, NumRogues).



 difficulty_of_state(StateId, Name, AgentClass, Difficulty):-
  state(StateId, Agents, _, _),
 num_agents_in_state(StateId,Name,NumWarriors,NumWizards,NumRogues),
  compute_difficulty(AgentClass, NumWarriors, NumWizards, NumRogues, Difficulty).

  compute_difficulty(warrior, NumWarriors, NumWizards, NumRogues, Difficulty) :-
    Difficulty is 5 * NumWarriors + 8 * NumWizards + 2 * NumRogues.
compute_difficulty(wizard, NumWarriors, NumWizards, NumRogues, Difficulty) :-
    Difficulty is 2 * NumWarriors + 5 * NumWizards + 8 * NumRogues.
compute_difficulty(rogue, NumWarriors, NumWizards, NumRogues, Difficulty) :-
    Difficulty is 8 * NumWarriors + 2 * NumWizards + 5 * NumRogues.




 easiest_traversable_state(StateId, AgentId, TargetStateId):-
   
  % Get list of all traversable states from the current state
    traversable_states(StateId, AgentId, TraversableStates),
    get_agent_from_id(AgentId,Agent,StateId),
    % Compute the difficulty of each traversable state
    findall(Difficulty-TargetStateId,
            (member(TargetStateId, TraversableStates),
             difficulty_of_state(TargetStateId, Agent.name, Agent.class, Difficulty),Difficulty>0),
            StateDifficulties),
    % Sort the states by difficulty and return the easiest one
    sort(StateDifficulties, [_-TargetStateId|_]),
    
    !.
   
action_distance(warrior, 1).
action_distance(wizard, 10).
action_distance(rogue, 5).


    
can_perform_action(Agent, StateId,UniverseId, Distance, TargetAgentId, Action) :-
    get_agent_from_id(TargetAgentId, TargetAgent, StateId),
    action_distance(Agent.class, RequiredDistance),
    % Check if the target is within the required distance
    (Distance > RequiredDistance ->
        (abs(Agent.x - TargetAgent.x) >= abs(Agent.y - TargetAgent.y) ->
            (Agent.x < TargetAgent.x -> Action = [move_right] ; Action = [move_left])
        ;
            (Agent.y < TargetAgent.y -> Action = [move_down] ; Action = [move_up]))
    ;
        % Get the name of the action that the agent can perform based on its class
        (Agent.class == warrior ->
            Action= [melee_attack,TargetAgentId]
        ; Agent.class == wizard ->
            Action = [magic_missile,TargetAgentId]
        ; Agent.class == rogue ->
            Action = [ranged_attack,TargetAgentId]
        ),
        % Check that the target is an enemy
        TargetAgent.class \== Agent.class
    ).
        





basic_action_policy(StateId, AgentId, Action) :-
    get_agent_from_id(AgentId,Agent,StateId),
    get_universe_and_time_for_state(StateId,UniverseId,LocalTime),
    % Try to find an easiest traversable state
    (easiest_traversable_state(StateId, AgentId, TargetStateId) ->
        get_universe_and_time_for_state(TargetStateId,TargetUniverseId,TargetTime),
        % If a traversable state is found, try to portal to it
        (can_perform_portal(UniverseId,TargetUniverseId,TargetTime, StateId, AgentId, TargetStateId) ->
            Action = [portal,TargetUniverseId]
        % If portal is not possible, try portal to now
        ; can_perform_portal_to_now(UniverseId,TargetUniverseId,StateId, AgentId, TargetStateId) ->
            Action = [portal_to_now,TargetUniverseId]
        % If neither portal nor portal-to-now is possible, try to attack
        ;  nearest_agent(StateId, AgentId, TargetAgentId, Distance),can_perform_action(Agent, StateId,UniverseId,Distance, TargetAgentId, Action)
        )
    % If no traversable state is found, try to perform an action

    ; nearest_agent(StateId, AgentId, TargetAgentId, Distance),can_perform_action(Agent, StateId,UniverseId, Distance, TargetAgentId, Action)
    % If no action is possible, rest
    ; Action = [rest]
    ).




        

