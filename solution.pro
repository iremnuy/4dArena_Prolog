distance(0, 0, 0).  % a dummy predicate to make the sim work.


%these are my own predicates




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
findall(D-Id, (get_agent_from_id(Id, Agent, StateId), Id \= AgentId, distance(CurrentAgent, Agent, D)), Distances),
% id is all the possible ids of any agent in the list that doesnt have the same id with the current one
min_member(Distance-NearestAgentId, Distances),
% make sure the nearest agent has a different name than the current agent
get_agent_from_id(NearestAgentId, NearestAgent, StateId),
NearestAgent.name \= CurrentAgent.name.




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
            (write(' cur Agents in state '), write(CurStateId), write(': '),write(Id),write(Agent.class),write(Agent.name), nl),
            multiverse_distance(StateId, AgentId, CurStateId, Id, Distance)
        ),
        Distances
    ),
    min_member(Distance-NearestStateId-NearestAgentId, Distances),
% make sure the nearest agent has a different name than the current agent
get_agent_from_id(NearestAgentId, NearestAgent, NearestStateId),
     TargetStateId = NearestStateId,
    TargetAgentId = NearestAgentId.
    

/* num_agents_in_state(StateId, Name, NumWarriors, NumWizards, NumRogues) :-
    state(StateId, AgentDict, _, _),
    findall(Warrior, (
        dict_pairs(AgentDict, _, AgentList),
        member(agent{class: warrior, name: WarriorName}, AgentList),
       \+ WarriorName = Name
    ), Warriors),
    length(Warriors, NumWarriors),
    findall(Wizard, (
        dict_pairs(AgentDict, _, AgentList),
        member(agent{class: wizard, name: WizardName}, AgentList),
        \+ WizardName = Name
    ), Wizards),
    length(Wizards, NumWizards),
    findall(Rogue, (
        dict_pairs(AgentDict, _, AgentList),
        member(agent{class: rogue, name: RogueName}, AgentList),
        format('Rogue name: ~w~n', [RogueName]),
        \+ RogueName = Name
          
    ), Rogues),
    length(Rogues, NumRogues). */

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




% easiest_traversable_state(StateId, AgentId, TargetStateId).
% basic_action_policy(StateId, AgentId, Action).
