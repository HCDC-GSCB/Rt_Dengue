# Instantaneous Reproduction number ($R_t$) estimation for Dengue in HCMC, Vietnam

This repository is a collaborative project between the **Department of Surveillance, Warning, Preparedness, and Emergency Response** (SWAPER), part of **Ho Chi Minh City Centre for Disease Control** (HCDC), and the Mathematical Modelling group at the **Oxford University Clinical Research Unit** (OUCRU), both based in Ho Chi Minh City (HCMC), Vietnam.

# Methodology
There are many ways to estimate the time-varying reproduction number $R_t$ for dengue:
- **Growth-rate methods** use $I(t)$ to estimate $r_t$, which is then used alongside $w(\tau)$ to estimate $R_t$ ([Wallinga–Lipsitch, 2006](https://royalsocietypublishing.org/rspb/article/274/1609/599/48188/How-generation-intervals-shape-the-relationship), which was used in [Siraj et. al., 2017](https://pmc.ncbi.nlm.nih.gov/articles/PMC5536440))
- **Renewal models** use $I_t$ and $w_{t,\tau}$, where $w_{t,\tau}$ is the infectivity profile at time $t$ and infection age $\tau$, which can be derived using the *Generation Interval (GI)*. With $I_t$ and $w_{t,\tau}$, we can then infer $R_t$. Both `EpiEstim` and `EpiFilter` are statistical frameworks that use renewal models to infer $R_t$
- **Transmission-tree methods** (or the **[Wallinga-Teunis method](https://pmc.ncbi.nlm.nih.gov/articles/PMC7110200/)**) estimate the likelihood of infector-infectee pairs given the times of onset, reconstruct probabilistic transmission trees, which can then be used to estimate $R^c_t$
- **Compartmental models** are used to fit the data and infer model parameters, which are then used to construct an NGM and derive $R_t$ ([Gostic et. al., 2020](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1008409))
- **Branching-process methods** model individual infections and disease transmission as a stochastic process, with $R_t$ determining the expected number of secondary infections, which can therefore be inferred from the observed epidemic trajectory



<!-- 1. **Generation Interval (GI)** inference:
    - GI defines the period of time between infections, i.e. between when the infector gets infected and when the infectee gets infected. This can be represented as a probability distribution, called the **GI distribution**
    - For dengue, this is a complex distribution, typically a convolution of 4 separate probability distributions, each representing a stage of the human-mosquito infection cycle: 
        1. Intrinsic Incubation Period (IIP)
        2. -> Transmission from human to mosquitoes
        3. -> Extrinsic Incubation Period (EIP)
        4. -> Transmission from mosquitoes to human (then back to step 1)
    - GI estimation typically requires data on date-of-infection or infector-infectee pairs. Neither of which are available for this study. As such, we can estimate GI by:
        - Using published fixed parameters ([Salje et al. 2021](https://www.nature.com/articles/s41467-021-21888-9))
            - We can also estimate GI ourselves using IIP and EIP estimates from [Rudolph et. al. 2014](https://pmc.ncbi.nlm.nih.gov/articles/PMC4015582/) and [Johansson et. al. 2012](https://pmc.ncbi.nlm.nih.gov/articles/PMC3511440/)
        - Mechanistically-derived from local data ([Siraj et. al. 2017](https://journals.plos.org/plosntds/article?id=10.1371/journal.pntd.0005797), [Mills et. al. 2025](https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/2041-210X.70110)), which generates dynamic GI that are temperature-dependent
        - 




[Codeço et al. 2018](https://www.sciencedirect.com/science/article/pii/S1755436517300907), [Choo et al. 2026](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1013820),  -->