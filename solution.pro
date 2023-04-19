distance(0, 0, 0).  % a dummy predicate to make the sim work.


%these are my own predicates



get_universe_and_time_for_state(StateId, UniverseId, Time) :-
    history(StateId, UniverseId, Time, _). %for a given state i retrieve universe and time


% travel cost based on agent class
travel_cost(wizard, 2).
travel_cost(_ , 5).


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




%nearest_agent_in_multiverse(StateId, AgentId, TargetStateId, TargetAgentId, Distance).

% num_agents_in_state(StateId, Name, NumWarriors, NumWizards, NumRogues).
% difficulty_of_state(StateId, Name, AgentClass, Difficulty).
% easiest_traversable_state(StateId, AgentId, TargetStateId).
% basic_action_policy(StateId, AgentId, Action).
