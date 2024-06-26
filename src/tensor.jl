
# ψ0 = MPS(s, n -> n == 1 ? "↓" : "↑")

"""
to_state(MPS::it.ITensors.MPS,M::Vector{it.Index{Int64}})

    Convert MPS to state vector
"""
to_state(MPS::it.ITensors.MPS,M::Vector{it.Index{Int64}})=sa.sparse(reshape(it.array(it.contract(MPS),reverse(M)),2^length(M)))
to_state(MPS::it.ITensors.MPS)=sa.sparse(reshape(it.array(it.contract(MPS),reverse(it.siteinds(MPS))),2^length(MPS)))

#this is wrong!
# to_state(MPS::it.ITensors.MPS)=round.(sa.sparse(reshape(it.contract(MPS).tensor,2^length(MPS))),digits=10)

function reflectMPS(psi::it.MPS)
    N = length(psi)
    psi_reflected = it.MPS(N)
    for i in 1:N
        A = psi[N - i + 1]
        psi_reflected[i] = A#it.dag(A)
    end
    return psi_reflected
end

# to_MPS(vec::Vector,M::Vector{it.Index{Int64}},maxdim::Int=500)=it.MPS(vec,M;maxdim=maxdim,cutoff=1e-10)|>reflectMPS
to_MPS(vec::Vector,M::Vector{it.Index{Int64}})=it.MPS(vec,M)|>reflectMPS

# to_MPS(vec::sa.SparseVector,M::Vector{it.Index{Int64}},maxdim::Int=500)=to_MPS(Vector(vec),M,maxdim)

"""
    to_MPS(vec::sa.SparseVector,M::Vector{it.Index{Int64}})

    Convert state vector to MPS
"""
to_MPS(vec::sa.SparseVector,M::Vector{it.Index{Int64}})=to_MPS(Vector(vec),M)

function tensor_to_matrix(tensor::it.ITensor)
    a=tensor.tensor.storage
    len=length(a)
    if len==2
        return a #pure
    else
        s=Int(log2(len))
        return reshape(a,(s,s))
    end
end

"""
this gives probability of measuring 0 and 1 on select_qubit after shots
"""
function sample(state::Union{sa.SparseVector,it.ITensors.MPS},shots::Int,select_qubit::Int)

    all_sample=hcat(sample(state,shots)...)[select_qubit,:]

    P1=sum(all_sample)/shots
    P0=1-P1

    return P0,P1
end

sample(state::sa.SparseVector,shots::Int=1)=int2bin.(sample_outcomes(state,shots),get_N(state))
sample(MPS::it.ITensors.MPS,shots::Int=1)=[it.sample!(MPS).-1 for i=1:shots]

inner(ψ::sa.SparseVector,MPS::it.ITensors.MPS)=ψ'to_state(MPS)
inner(MPS::it.ITensors.MPS,ψ::sa.SparseVector)=inner(ψ,MPS)
inner(ψ::sa.SparseVector,ψ2::sa.SparseVector)=ψ'ψ2
inner(MPS::it.ITensors.MPS,MPS2::it.ITensors.MPS)=it.inner(MPS',MPS2)

"""
    fidelity(ψ::sa.SparseVector,ψ2::sa.SparseVector)
"""
fidelity(ψ::sa.SparseVector,ψ2::sa.SparseVector)=abs2(ψ'ψ2)

# inner_slow(MPS::it.ITensors.MPS,ψ::sa.SparseVector,maxdim::Int)=it.inner(MPS',to_MPS(ψ,it.siteinds(MPS),maxdim))
# inner_slow(MPS::it.ITensors.MPS,ψ::sa.SparseVector)=it.inner(MPS',to_MPS(ψ,it.siteinds(MPS)))


# function entanglement_entropy(psi::it.MPS, b::Int)
#     s = it.siteinds(psi)  
#     it.orthogonalize!(psi, b)
#     _,S = it.svd(psi[b], (it.linkind(psi, b-1), s[b]))
#     SvN = 0.0
#     for n in 1:it.dim(S, 1)
#       p = S[n,n]^2
#       SvN -= p * log(p)
#     end
#     return SvN
# end


#pastaq
function entanglement_entropy(psi::it.MPS)
    ψ = it.normalize!(copy(psi))
    N = length(ψ)
    bond = N ÷ 2
    it.orthogonalize!(ψ, bond)
  
    row_inds = (it.linkind(ψ, bond - 1), it.siteind(ψ, bond))
    u, s, v = it.svd(ψ[bond], row_inds)
  
    S = 0.0
    for n in 1:it.dim(s, 1)
      λ = s[n, n]^2
      S -= λ * log(λ + 1e-20)
    end
    return S
  end