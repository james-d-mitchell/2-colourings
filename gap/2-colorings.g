# The function below is for converting a permutation group in to the input for
# IVMPG::PermutationGroup, it does not work.
# IVMPG := function(G)
#   local S, result, depth, N, K;
#   S := StabChain(G);
#   N := LargestMovedPoint(G);
#   K := Length(BaseStabChain(S));
#   result := List([1 .. N], x -> []);
#   depth := 1;
#   while depth <= K do
#     Append(result[depth], List(Compacted(S.transversal), x -> ListPerm(x, N)));
#     S := S.stabilizer;
#     depth := depth + 1;
#   od;
#   while depth <= Length(result) do
#     Add(result[depth], [1 .. N]);
#     depth := depth + 1;
#   od;
#   result := String(result - 1);
#   result := ReplacedString(result, "[", "{");
#   result := ReplacedString(result, "]", "}");
#   return result;
# end;

IVMPG := function(G)
  local S, result, N, base, pt;
  N := LargestMovedPoint(G);
  result := List([1 .. N], x -> []);
  base := BaseOfGroup(G);
  for pt in base do
    S := Stabilizer(G, pt);
    Append(result[pt], List(RightTransversal(G, S), x -> ListPerm(x, N)));
    G := S;
  od;
  for pt in [1 .. N] do
    if IsEmpty(result[pt]) then
      Add(result[pt], [1 .. N]);
    fi;
  od;
  result := STRINGIFY(result - 1);
  result := ReplacedString(result, "[", "{");
  result := ReplacedString(result, "]", "}");
  return result;
end;


# Seems that OrbitsDomain is faster than this
FindIt := function(D)
  local G, N, result, act, f, next;
  if IsDigraph(D) then
  G := AutomorphismGroup(D);
  N := DigraphNrVertices(D);
else 
  G := D;
  N := LargestMovedPoint(G);
fi;
  result := HashMap();
  act := function(pt, x)
    pt := BlistNumber(pt, N);
    pt := Permuted(pt, x);
    return NumberBlist(pt);
  end;
  for f in [1 .. 2 ^ N] do
    next := CanonicalImage(G, f, act);
    if not next in result then
      result[next] := true;
    fi;
  od;
  return result;
end; 

DigraphBlist := function(blist)
local out, i;
  out := [[], []];
  for i in [3 .. Length(blist) + 2] do
    if blist[i - 2] then
      out[i] := [1];
    else
      out[i] := [2];
    fi;
  od;
  return DigraphNC(out);
end;

BlistDigraph := function(digraph)
  local out, i, nbs, n;
  n := DigraphNrVertices(digraph); 
  nbs := OutNeighbours(digraph); 
  out := BlistList([1 .. n - 2], []);
  for i in [3 .. n] do
    out[i - 2] := nbs[i][1] = 1;
  od;
  return out;
end;

FindIt2 := function(D)
  local G, N, result, act, f, next;
  N := DigraphNrVertices(D);
  result := HashMap();
  for f in [1 .. 2 ^ N] do
    D := BlissCanonicalDigraph(DigraphBlist(BlistNumber(f, N)));
    next := NumberBlist(BlistDigraph(D));
    if not next in result then
      result[next] := true;
    fi;
  od;
  return result;
end; 
