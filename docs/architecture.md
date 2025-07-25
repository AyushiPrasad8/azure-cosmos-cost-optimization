# Architecture Details

                                    ┌────────────────────────┐
                                    │    API Consumer        │
                                    └──────────┬─────────────┘
                                               │
                                               ▼
                                    ┌────────────────────────┐
                                    │    Billing Read API    │
                                    └──────────┬─────────────┘
                                               │
                  Record Found                 │              Record Not Found
               (recent < 3 months)             │              (older > 3 months)
                     │                         ▼
                     ▼             ┌─────────────────────────────┐
            ┌────────────────┐     │ Azure Function (Cold Fetch) │◄────────┐
            │  Cosmos DB     │     └──────────┬──────────────────┘         │
            │ (Active Zone)  │                │                            │
            └──────┬─────────┘         Fetch from Blob Storage             │
                   │                     ▼                                 │
                   │            ┌───────────────────────┐                  │
                   │            │ Azure Blob Storage    │                  │
                   │            │  (cold data archive)  │                  │
                   │            └──────────┬────────────┘                  │
                   │                       │                               │
                   │             Restore to Cosmos DB                      │
                   └──────────────────────┘                                │
                                                                           │
                        Nightly Trigger (Daily Archival)                   │
                                  ▼                                        │
                        ┌─────────────────────────────┐                    │
                        │ Azure Function (Archiver)   │◄───────────────────┘
                        │ Timer Trigger (daily)       │
                        └──────────┬──────────────────┘
                                   │
                          Query records older than 90 days
                                   │
                                   ▼
                        ┌─────────────────────────────┐
                        │   Cosmos DB (Old Records)   │
                        └──────────┬──────────────────┘
                                   │
                         Compress and Upload to Blob
                                   ▼
                        ┌────────────────────────────┐
                        │ Azure Blob Storage (Cold)  │
                        └────────────────────────────┘


