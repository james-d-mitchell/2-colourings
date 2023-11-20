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

TestCaseHead := function(name, number, degree)
  # TODO use DigraphFromGraph6String("string-of-rep") rather than just a
  # number
  return StringFormatted(
  "TEST_CASE(\"{1}\", \"[{2}][quick]\") {{\n  PermutationGroup<> G(\"{1}\", {3},", 
        name, number, degree);
end;

TestCaseTail := function(degree)
  local result, i;
  result := StringFormatted(
    "  REQUIRE(number_of_2_colourings(G, {}) == 0);\n", degree);
  for i in [1 .. degree] do
    Append(result, 
           StringFormatted("REQUIRE(G.elements_of_depth({}, 1) == \n",
                           i));
    Append(result, "decltype(G.elements_of_depth(0))({}));\n");
  od;
  Append(result, "}\n");
  return result;
end;

ErrorFormatted := function(args...)
  Error(CallFuncList(StringFormatted, args));
end;

IVMPG_CheckArgs := function(args...)
  if Length(args) = 1 then
    if not IsDigraph(args[1]) then
      Error("Expected the argument to be a digraph");
    fi;
  elif Length(args) = 2 then
    if not IsPermGroup(args[1]) then
      ErrorFormatted("Expected the 1st argument to be a perm group, not a {}",
                     TNAM_OBJ(args[1]));
    elif not IsPosInt(args[2]) then
      ErrorFormatted("Expected the 2nd argument to be a pos. int, not a {}",
                     TNAM_OBJ(args[1]));
    elif args[2] < LargestMovedPoint(args[1]) then
      ErrorFormatted("Expected the 2nd argument to be at most {}, but found {}",
                      LargestMovedPoint(args[1]), 
                      args[2]);
    else 
      ErrorFormatted("Expected 1 or 2 arguments, found {}", Length(args));
    fi;
  fi;
end;

IVMPG_String := function(args...)
  local G, N, test_case_name, result, base, pt, S;
  CallFuncList(IVMPG_CheckArgs, args);
  if Length(args) = 1 then
    G := AutomorphismGroup(args[1]);
    N := DigraphNrVertices(args[1]);
    test_case_name := ReplacedString(PrintString(args[1]), "\"", "\\\"");
  elif Length(args) = 2 then
    G := args[1];
    N := args[2];
    test_case_name := StructureDescription(G);
  fi;

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
  result := String(result - 1);
  result := ReplacedString(result, "[", "{");
  result := ReplacedString(result, "]", "}");
  Append(result, ");\n");
  result := Concatenation(TestCaseHead(test_case_name, 0, N), result);
  Append(result, TestCaseTail(N));
  return result;
end;

IVMPG_File := function(fnam, mode, args...)
  local str;
  if not IsString(fnam) then
    ErrorFormatted("Expected the 1st argument to be a string, but found {}",
                   TNAM_OBJ(fnam));
  elif not IsBool(mode) and mode in [true, false] then
    ErrorFormatted("Expected the 2nd argument to be true or false, but found {}",
                   mode);
  fi;

  str := CallFuncList(IVMPG_String, args);
  PrintFormatted("Writing {} ....\n", fnam);
  return FileString(fnam, str, mode);
end;

# Return a list of representative (under the action by the symmetric group by
# conjugation). automorphism groups of the list of digraphs
# Ds. Assumes that every digraph in Ds has the same number of nodes. 
ConjugacyClassRepsAutomorphismGroups := function(Ds)
  local result, G, N, Gs, D, tmp;
  if IsList(Ds) then
    N := DigraphNrVertices(Ds[1]);
  else 
    tmp := ShallowCopy(Ds);
    N := DigraphNrVertices(NextIterator(Ds));
    Ds := tmp;
  fi;
  Gs := [];
  result := [];

  for D in Ds do
    G := AutomorphismGroup(D);
    if ForAll(Gs, x -> not IsConjugate(SymmetricGroup(N), x, G)) then
      Add(Gs, G);
      Add(result, D);
    fi;
  od;
  return result;
end;

# Writes a C++ test case for each of the graphs in the list of graphs Ds to a
# file.
IVMPGDigraphs := function(Ds)
  local count, N, fnam, Gs, G, name;
  count := 1;
  N := DigraphNrVertices(Ds[1]);
  fnam := StringFormatted("graph{}", N);
  Exec(StringFormatted("rm -f {}", fnam));
  Gs := ConjugacyClassRepsAutomorphismGroups(Ds);
  for G in Gs do
    name := StringFormatted("{}_{}", fnam, count);
    IVMPG(G, N, name, fnam);
    count := count + 1;
  od;
end;

# Seems to be https://oeis.org/A346673
# gap> NrSubgroups(5);
# 9
# gap> NrSubgroups(6);
# 23
# gap> NrSubgroups(7);
# 31
# gap> NrSubgroups(8);
# 71
# gap> NrSubgroups(9);
# 103
# gap> time;
# 32787
# gap> NrSubgroups(10);
# 213
# gap> time;
# 930147
NrSubgroups := function(n)
  local Ds;
  Ds := ReadDigraphs(StringFormatted("/Users/jdm/git/2-colorings/gap/graph{}.g6", n));
  return Length(ConjugacyClassRepsAutomorphismGroups(Ds));
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
