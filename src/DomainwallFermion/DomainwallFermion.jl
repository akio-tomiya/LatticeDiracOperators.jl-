struct D5DW_Domainwall_operator{Dim,T,fermion,wilsonfermion} <: Dirac_operator{Dim}   where  T <: AbstractGaugefields
    U::Array{T,1}
    wilsonoperator::Wilson_Dirac_operator{Dim,T,wilsonfermion} 
    mass::Float64
    _temporary_fermi::Array{fermion,1}
    L5::Int64
    eps_CG::Float64
    MaxCGstep::Int64
    verbose_level::Int8
    method_CG::String
    verbose_print::Verbose_print
    _temporary_fermion_forCG::Vector{fermion}
    boundarycondition::Vector{Int8}

end


function D5DW_Domainwall_operator(U::Array{<: AbstractGaugefields{NC,Dim},1},x,parameters,mass) where  {NC,Dim}
    @assert haskey(parameters,"L5") "parameters should have the keyword L5"
    L5 = parameters["L5"]
    @assert L5 == x.L5 "L5 in Dirac operator and fermion fields should be same. Now L5 = $L5 and x.L5 = $(x.L5)"
    boundarycondition = check_parameters(parameters,"boundarycondition",[1,1,1,-1])
    T = eltype(U)

    #Parameters for Wilson operator
        r = 1
        M = check_parameters(parameters,"M",-1)
        #@assert haskey(parameters,"M") "parameters should have the keyword M"
        #M = parameters["M"]
        κ_wilson = 1/(8r+2M)
        parameters_wilson = Dict()
        parameters_wilson["κ"] = κ_wilson
        parameters_wilson["numtempvec"] = 4 
        parameters_wilson["numtempvec_CG"] = 1
        parameters_wilson["boundarycondition"] = boundarycondition 
        x_wilson  = x.w[1]
        wilsonoperator = Wilson_Dirac_operator(U,x_wilson,parameters_wilson)
    #--------------------------------


    xtype = typeof(x)
    num = 1
    _temporary_fermi = Array{xtype,1}(undef,num)
    for i=1:num
        _temporary_fermi[i] = similar(x)
    end

    numcg = 7
    _temporary_fermion_forCG= Array{xtype,1}(undef,numcg)
    for i=1:numcg
        _temporary_fermion_forCG[i] = similar(x)
    end


    eps_CG = check_parameters(parameters,"eps_CG",default_eps_CG)
    #println("eps_CG = ",eps_CG)
    MaxCGstep = check_parameters(parameters,"MaxCGstep",default_MaxCGstep)

    verbose_level = check_parameters(parameters,"verbose_level",2)
    verbose_print = Verbose_print(verbose_level)

    method_CG = check_parameters(parameters,"method_CG","bicg")
    #println("xtype ",xtype)
    #println("D ", typeof(wilsonoperator))

    return D5DW_Domainwall_operator{Dim,T,xtype,typeof(x_wilson)}(
        U,
        wilsonoperator,
        mass,
        _temporary_fermi,
        L5,
        eps_CG,
        MaxCGstep,
        verbose_level,
        method_CG,
        verbose_print,
        _temporary_fermion_forCG,
        boundarycondition
        )
end



function (D::D5DW_Domainwall_operator{Dim,T,fermion,wilsonfermion})(U) where {Dim,T,fermion,wilsonfermion}
    return D5DW_Domainwall_operator{Dim,T,fermion,wilsonfermion}(
        U,
        D.wilsonoperator(U),
        D.mass,
        D._temporary_fermi,
        D.L5,
        D.eps_CG,
        D.MaxCGstep,
        D.verbose_level,
        D.method_CG,
        D.verbose_print,
        D._temporary_fermion_forCG,
        D.boundarycondition
    )
end

struct Adjoint_D5DW_Domainwall_operator{T} <: Adjoint_Dirac_operator
    parent::T
end






struct Domainwall_Dirac_operator{Dim,T,fermion,wilsonfermion} <: Dirac_operator{Dim}  where T <: AbstractGaugefields
    U::Array{T,1}
    D5DW::D5DW_Domainwall_operator{Dim,T,fermion,wilsonfermion}
    D5DW_PV::D5DW_Domainwall_operator{Dim,T,fermion,wilsonfermion}
    mass::Float64
    eps_CG::Float64
    MaxCGstep::Int64
    verbose_level::Int8
    method_CG::String
    verbose_print::Verbose_print
    boundarycondition::Vector{Int8}

end

function Domainwall_Dirac_operator(U::Array{<:AbstractGaugefields{NC,Dim},1},x,parameters) where  {NC,Dim}
    @assert haskey(parameters,"mass") "parameters should have the keyword mass"
    mass = parameters["mass"]
    D5DW = D5DW_Domainwall_operator(U,x,parameters,mass)
    D5DW_PV = D5DW_Domainwall_operator(U,x,parameters,1)

    boundarycondition = check_parameters(parameters,"boundarycondition",[1,1,1,-1])


    eps_CG = check_parameters(parameters,"eps_CG",default_eps_CG)
    #println("eps_CG = ",eps_CG)
    MaxCGstep = check_parameters(parameters,"MaxCGstep",default_MaxCGstep)

    verbose_level = check_parameters(parameters,"verbose_level",2)
    verbose_print = Verbose_print(verbose_level)

    method_CG = check_parameters(parameters,"method_CG","bicg")

    return Domainwall_Dirac_operator{Dim,eltype(U),typeof(x),typeof(x.w[1])}(
            U,
            D5DW,D5DW_PV,mass,
            eps_CG,
            MaxCGstep,
            verbose_level,
            method_CG,
            verbose_print,
            boundarycondition    
    )
end


function (D::Domainwall_Dirac_operator{Dim,T,fermion,wilsonfermion})(U) where {Dim,T,fermion,wilsonfermion}
    return Domainwall_Dirac_operator{Dim,T,fermion,wilsonfermion}(
        U,
        D.D5DW(U),D.D5DW_PV(U),
        D.mass,
        D.eps_CG,
        D.MaxCGstep,
        D.verbose_level,
        D.method_CG,
        D.verbose_print,
        D.boundarycondition    
    )
end


function get_temporaryvectors(A::T) where T <: Domainwall_Dirac_operator
    return A.D5DW._temporary_fermi
end

function get_temporaryvectors_forCG(A::T) where T <: Domainwall_Dirac_operator
    return A.D5DW._temporary_fermion_forCG
end

struct Adjoint_Domainwall_operator{Dim,T,fermion,wilsonfermion} <: Adjoint_Dirac_operator 
    parent::Domainwall_Dirac_operator{Dim,T,fermion,wilsonfermion}
end

function Base.adjoint(A::D5DW_Domainwall_operator)
    Adjoint_D5DW_Domainwall_operator(A)
end

function Base.adjoint(A::Domainwall_Dirac_operator{Dim,T,fermion,wilsonfermion}) where {Dim,T,fermion,wilsonfermion} 
    Adjoint_Domainwall_operator{Dim,T,fermion,wilsonfermion}(A)
end



struct DdagD_Domainwall_operator{Dim,T,fermion,wilsonfermion} <: DdagD_operator 
    dirac::Domainwall_Dirac_operator{Dim,T,fermion,wilsonfermion} 
    function DdagD_Domainwall_operator(U::Array{<: AbstractGaugefields{NC,Dim},1},x,parameters) where  {NC,Dim}
        return new{Dim,eltype(U),typeof(x),typeof(x.w[1])}(Domainwall_Dirac_operator(U,x,parameters))
    end

    function DdagD_Domainwall_operator(D::Domainwall_Dirac_operator{Dim,T,fermion,wilsonfermion}) where {Dim,T,fermion,wilsonfermion}
        return new{Dim,T,fermion,wilsonfermion}(D)
    end
end

struct D5DWdagD5DW_Wilson_operator{T} <: DdagD_operator 
    dirac::T
    function D5DWdagD5DW_Wilson_operator(U::Array{T,1},x,parameters,mass) where  T <: AbstractGaugefields
        return new{T}(D5DW_Domainwall_operator(U,x,parameters,mass))
    end

    function D5DWdagD5DW_Wilson_operator(D::Domainwall_Dirac_operator{Dim,T,fermion,wilsonfermion}) where {Dim,T,fermion,wilsonfermion}
        dtype = typeof(D.D5DW)
        return new{dtype}(D.D5DW)
    end

    function D5DWdagD5DW_Wilson_operator(D::D5DW_Domainwall_operator{Dim,T,fermion,wilsonfermion}) where {Dim,T,fermion,wilsonfermion}
        dtype = typeof(D)
        return new{dtype}(D)
    end
end

function LinearAlgebra.mul!(y::T1,A::T2,x::T3) where {T1 <:AbstractFermionfields,T2 <: D5DWdagD5DW_Wilson_operator, T3 <:AbstractFermionfields}
    temp = A.dirac._temporary_fermi[1]
    mul!(temp,A.dirac,x)
    mul!(y,A.dirac',temp)

    return
end



function LinearAlgebra.mul!(y::T1,A::T2,x::T3) where {T1 <:AbstractFermionfields,T2 <: D5DW_Domainwall_operator, T3 <:AbstractFermionfields}
    D5DWx!(y,A.U,x,A.mass,A.wilsonoperator,A.L5) 
    return
end

function LinearAlgebra.mul!(y::T1,A::T2,x::T3) where {T1 <:AbstractFermionfields,T2 <: Adjoint_D5DW_Domainwall_operator, T3 <:AbstractFermionfields}
    D5DWdagx!(y,A.parent.U,x,A.parent.mass,A.parent.wilsonoperator,A.parent.L5) 
end


function LinearAlgebra.mul!(y::T1,A::T2,x::T3) where {T1 <:AbstractFermionfields,T2 <: Adjoint_Domainwall_operator, T3 <:AbstractFermionfields}
        
    #A = D5DW(m)*D5DW(m=1)^(-1)
    #=
    A^+ = [D5DW(m)*D5DW(m=1)^(-1)]^+
        = D5DW(m=1)^(-1)^+ D5DW(m)^+
        = [D5DW(m=1)^+]^(-1) D5DW(m)^+
    y = A^+*x = [D5DW(m=1)^+]^(-1) D5DW(m)^+*x
    =#
    mul!(A.parent.D5DW_PV._temporary_fermi[1],A.parent.D5DW',x)
    bicg(y,A.parent.D5DW_PV',A.parent.D5DW_PV._temporary_fermi[1],
        maxsteps = 10000)
        #verbose = Verbose_3()) 
    
    return
end

function LinearAlgebra.mul!(y::T1,A::T2,x::T3) where {T1 <:AbstractFermionfields,T2 <: Domainwall_Dirac_operator, T3 <:AbstractFermionfields}
    #A = D5DW(m)*D5DW(m=1))^(-1)
    #y = A*x = D5DW(m)*D5DW(m=1))^(-1)*x
    bicg(A.D5DW_PV._temporary_fermi[1],A.D5DW_PV,x) 
    mul!(y,A.D5DW,A.D5DW_PV._temporary_fermi[1])

    #error("Do not use Domainwall_operator directory. Use D5DW_Domainwall_operator M = D5DW(m)*D5DW(-1)^{-1}")
    #D5DWx!(y,A.U,x,A.m,A.wilsonoperator._temporary_fermi) 
    return
end


include("./DomainwallFermion_5d_wing.jl")

function Initialize_DomainwallFermion(u::AbstractGaugefields{NC,Dim},L5) where {NC,Dim}
    _,_,NN... = size(u)
    return DomainwallFermion_5D_wing(L5,NC,NN...) 
end


function bicg(x,A::Domainwall_Dirac_operator,b;eps=1e-10,maxsteps = 1000,verbose = Verbose_print(2)) #A*x = b -> x = A^-1*b
    #A = D5DW(m)*D5DW(m=1))^(-1)
    #A^-1 = D5DW(m=1)*DsDW(m)^-1
    #x = A^-1*b = D5DW(m=1)*DsDW(m)^-1*b
    bicg(A.D5DW._temporary_fermi[1],A.D5DW,b;eps=eps,maxsteps = maxsteps,verbose = verbose) 
    mul!(x,A.D5DW_PV,A.D5DW._temporary_fermi[1])
end



function bicg(x,A::Adjoint_Domainwall_operator,b;eps=1e-10,maxsteps = 1000,verbose = Verbose_print(2)) where T #A*x = b -> x = A^-1*b
    #A = D5DW(m)*D5DW(m=1)^(-1)
    #A' = (D5DW(m=1)^+)^(-1) D5DW(m)^+
    #A'^-1 = D5DW(m)^+^-1 D5DW(m=1)^+
    #x = A'^-1*b =D5DW(m)^+^-1 D5DW(m=1)^+*b
    mul!(A.parent.D5DW._temporary_fermi[1],A.parent.D5DW_PV',b)
    bicgstab(x,A.parent.D5DW',A.parent.D5DW._temporary_fermi[1];eps=eps,maxsteps = maxsteps,verbose = verbose) 

end

function bicgstab(x,A::Domainwall_Dirac_operator,b;eps=1e-10,maxsteps = 1000,verbose = Verbose_print(2)) #A*x = b -> x = A^-1*b
    #A = D5DW(m)*D5DW(m=1))^(-1)
    #A^-1 = D5DW(m=1)*DsDW(m)^-1
    #x = A^-1*b = D5DW(m=1)*DsDW(m)^-1*b
    bicg(A.D5DW._temporary_fermi[1],A.D5DW,b;eps=eps,maxsteps = maxsteps,verbose = verbose) 
    mul!(x,A.D5DW_PV,A.D5DW._temporary_fermi[1])
end



function bicgstab(x,A::Adjoint_Domainwall_operator,b;eps=1e-10,maxsteps = 1000,verbose = Verbose_print(2)) where T #A*x = b -> x = A^-1*b
    #A = D5DW(m)*D5DW(m=1)^(-1)
    #A' = (D5DW(m=1)^+)^(-1) D5DW(m)^+
    #A'^-1 = D5DW(m)^+^-1 D5DW(m=1)^+
    #x = A'^-1*b =D5DW(m)^+^-1 D5DW(m=1)^+*b
    mul!(A.parent.D5DW._temporary_fermi[1],A.parent.D5DW_PV',b)
    bicgstab(x,A.parent.D5DW',A.parent.D5DW._temporary_fermi[1];eps=eps,maxsteps = maxsteps,verbose = verbose) 

end

function cg(x,A::DdagD_Domainwall_operator,b;eps=1e-10,maxsteps = 1000,verbose = Verbose_print(2))
    #=
    A^-1 = ( (D5DW(m)*D5DW(m=1))^(-1))^+ D5DW(m)*D5DW(m=1))^(-1) )^-1
      = ( D5DW(m=1)^+)^(-1) D5DW(m)^+ D5DW(m)*D5DW(m=1))^(-1) )^-1
      = D5DW(m=1) (  D5DW(m)^+ D5DW(m) )^(-1) )^-1 D5DW(m=1)^+
    x = A^-1*b = D5DW(m=1) (  D5DW(m)^+ D5DW(m) )^(-1)  D5DW(m=1)^+*b
    =#
    mul!(A.dirac.D5DW_PV._temporary_fermi[1],A.dirac.D5DW_PV',b) #D5DW(m=1)^+*b

    temp = A.dirac.D5DW_PV._temporary_fermi[1]
    cg(A.dirac.D5DW._temporary_fermi[1],A.DdagD,temp;eps=eps,maxsteps = maxsteps,verbose = verbose) #(  D5DW(m)^+ D5DW(m) )^(-1)  D5DW(m=1)^+*b
    mul!(x,A.dirac.D5DW_PV,A.dirac.D5DW._temporary_fermi[1])
end
