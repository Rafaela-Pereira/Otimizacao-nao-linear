using JuMP, DataFrames, CSV
#lista de materias
materias=CSV.File("C://Users//Samsung-PC//Dropbox//My PC (DESKTOP-QMGT6L8)//Documents//UFPR-disciplinas//Aula-Prog nao linear -Abel//Projeto 1//materias1.csv")
lista_materias = DataFrame(materias)
#lista preferencias dos professores
Professores = CSV.File("C://Users//Samsung-PC//Dropbox//My PC (DESKTOP-QMGT6L8)//Documents//UFPR-disciplinas//Aula-Prog nao linear -Abel//Projeto 1//preferenciasProfes.csv")
lista_professores = DataFrame(Professores)
#parâmetro duração da aula
DU = zeros(5,7,92);
for k=1:92
    DU[:,:,k] .= lista_materias[1 + (k-1) * 5: 5 + (k-1) * 5, 2:8]
end
#parâmetro binário que marca se a turma tem aula no dia d e horrario h
HT = copy(DU)
HT = HT/2
#preferencias -pesos
preferencias = zeros(Int,52,92);
preferencias .= lista_professores[:,2:93];
pesos = copy(preferencias);
##vetor de dias
dias = CSV.File("C://Users//Samsung-PC//Dropbox//My PC (DESKTOP-QMGT6L8)//Documents//UFPR-disciplinas//Aula-Prog nao linear -Abel//Projeto 1//V.csv")
dias_aulas = DataFrame(dias)
#vetor de dias
V = dias_aulas[1:5,2:93]
v=ones(5,92)
v.=V

#O modelo!!!
using  Ipopt
using Cbc
using LinearAlgebra
using Juniper
using Gurobi

model = Model(Gurobi.Optimizer)

P = size(preferencias,1) # número de professores
M = size(preferencias,2) # número de matérias
H = 7 # horarios
D = 5 # dias

@variable(model, x[1:P, 1:M] ≥ 0, Bin) #P*M var de decisão

@constraint(model,[p=1:P, d=1:D, h=1:H], sum(HT[d, h, t] * x[p,t] for t=1:M) ≤ 1)
@constraint(model, [t=1:M], sum(x[p,t] for p=1:P) == 1)
@constraint(model, [p=1:P], sum(DU[d, h, t]*x[p,t] for t=1:M, d=1:D, h=1:H) ≥ 6)
@constraint(model, [p=1:P], sum(DU[d, h, t]*x[p,t] for t=1:M, d=1:D, h=1:H) ≤ 12);

# Primeiro maximizando o modelo
@objective(model, Max, sum(pesos[p,t]*x[p,t] for p=1:P, t=1:M) - sum(x[p,t]*x[p,i]*(norm(v[:,t] - v[:,i]))^2 for p=1:P, t=1:M, i=1:M));

optimize!(model) #resolver

resp = value.(x)

# média da do grau de  satisfação
sum(sum(resp .* pesos, dims=2)) / 52

#todos professores com uma unica matéria
sum(resp, dims=1)

# satisfação individual
satisfacao=sum(resp .* pesos, dims=2)

#Quantidade de professores por pesos na escolha da disciplina
A = value.(x) .* preferencias
length(findall(A .== 5))
length(findall(A .== 4))
length(findall(A .== 3))
length(findall(A .== 2))
length(findall(A .== 5))

#sobre a penalização
QtdeDisciplinasRecebidas=sum(resp .*ones(52,92), dims=2)
#quantidade de porfessores que receberam 3,2 ou 1 disciplina
length(findall(QtdeDisciplinasRecebidas .== 3))
length(findall(QtdeDisciplinasRecebidas .== 2))
length(findall(QtdeDisciplinasRecebidas .== 1))
#professores que receberam duas e três matérias
ProfeDuasMaterias=[1;2;4;5;6;7;8;10;12;15;16;17;18;20;22;23;24;25;
27;30;31;32;33;35;36;37;38;40;42;43;44;45;46;47;48;49;50;51]
ProfeTresMaterias=[39]
#valores da penalização
x=zeros(2)
penalizacao=zeros(38)
for i=1:38
x=findall(resp[ProfeDuasMaterias[i],:].==1)
penalizacao[i]=norm(v[:,x[1]]-v[:,x[2]])^2
end
penalizacao
findall(penalizacao.==1)
#penalização do professor com 3 materias,disciplina 8,30 e 45
norm(v[:,8]-v[:,45])^2+norm(v[:,45]-v[:,30])^2+norm(v[:,8]-v[:,30])^2

#valor da função objetivo
sum(satisfacao)-2*sum(penalizacao)

#------------------------MODELO LINEAR------------------------

modelo = Model(Gurobi.Optimizer)

P = size(preferencias,1) # número de professores
M = size(preferencias,2) # número de matérias
H = 7 # horarios
D = 5 # dias

@variable(modelo, x[1:P, 1:M] ≥ 0, Bin) #P*M var de decisão

@constraint(modelo,[p=1:P, d=1:D, h=1:H], sum(HT[d, h, t] * x[p,t] for t=1:M) ≤ 1)
@constraint(modelo, [t=1:M], sum(x[p,t] for p=1:P) == 1)
@constraint(modelo, [p=1:P], sum(DU[d, h, t]*x[p,t] for t=1:M, d=1:D, h=1:H) ≥ 6)
@constraint(modelo, [p=1:P], sum(DU[d, h, t]*x[p,t] for t=1:M, d=1:D, h=1:H) ≤ 12);

@objective(modelo, Max, sum(pesos[p,t]*x[p,t] for p=1:P, t=1:M));

optimize!(modelo) #resolver

SolLinear=value.(x)

#observando a grade horária
QtdeDisciplinasL=sum(SolLinear .*ones(52,92), dims=2)
#quantidade de professores que receberam 2 ou 1 disciplina
length(findall(QtdeDisciplinasL .== 2))
length(findall(QtdeDisciplinasL .== 1))
#professores com duas disciplinas
ProfesDuasDisc=[1;2;4;5;6;7;8;10;12;13;14;15;16;17;18;20;22;
23;25;26;27;29;30;31;32;34;35;36;37;38;39;40;42;43;44;45;46;47;50;51]

#grade horária
xl=zeros(2)
penalizacaoL=zeros(40)
for i=1:40
xl=findall(SolLinear[ProfesDuasDisc[i],:].==1)
penalizacaoL[i]=norm(v[:,xl[1]]-v[:,xl[2]])^2
end
sum(penalizacaoL)
findall(penalizacaoL.==4)

