# Deploy Peach with CloudDrive2 and Jackett on an InstaBox Free Machine

## Set the architecture and the split of work

- Run Peach, CloudDrive2 and Jackett as three Docker containers on one InstaBox free machine, with the Peach port as the only published port.

- Bind CloudDrive2 and Jackett to host loopback only, and let Peach reach Jackett over a shared Docker network instead of a published port.

- Drive the machine through the InstaBox HTTPS API from `muse.exec`, and leave logins, token creation in web pages and pastes inside the user SSH session to the user.

- Keep every credential out of chat and out of memory, and store the InstaBox API key only in the goal hidden files folder with mode 600.

- Ask the user for a fresh API key when calls start returning 401 with expired_key or revoked_key, and never work around an expired key.

- Reuse a second InstaBox account machine for Peach when the user already runs nodes on the first account, because one free account holds one machine and the two workloads stay independent.

## Prepare InstaBox API access

- Send requests to https://api.instabox.sh with the API key in the `X-API-Key` header.

- Post exec calls with a JSON body whose field is `cmd`, because the field name `command` returns 400.

- Add an `Idempotency-Key` header when creating a published port through the ports API.

- Treat /data as the only persistent storage and put every compose project under /data/home.

- Expect the machine to pause after about 30 idle minutes, and wake an idle paused machine with an API exec call or a visit to a published port.

- Treat a manually suspended machine as different, because a port visit did not wake it in testing while the idle self pause woke within seconds, so only an explicit resume restarts it.

- Report the template max run minutes as a soft figure, because the machine in the verified run kept running past its stated 120 minute cap, and promise neither a hard stop nor its absence.

- Skip SSH from the agent side, because outbound SSH from the agent sandbox is blocked on every tested port while the user SSH token works from their own computer.

## Deploy Peach

- Write the Peach compose file at /data/home/peach/docker-compose.yml with the image longmeidao/peach in the edge tag and restart set to unless-stopped.

- Bind /data/home/peach/data, /data/home/peach/update and /data/home/peach/media to /data, /update and /media in the container.

- Publish container port 8900 through the InstaBox ports API, and verify the public URL answers /healthz with 200 before involving the user.

- Tell the user the 20 GiB disk holds the app, the database and generated artwork only, and route media through the cloud drive features instead of local storage.

## Finish first-run setup through the user SSH tunnel

- Read Peach ADR-0149 before promising any setup route, because Peach refuses first-run setup from non local clients and the published port returns 403 for the setup questions.

- Treat the same local gate as permanent for the configuration pages after setup, and read a configuration load failure over the public URL as designed behavior rather than a fault.

- Set PEACH_ACCESS_PASSWORD only to prewrite the password policy, and never present it as a way through the setup gate.

- Refuse to build header stripping proxies or other forwarding workarounds around the local gate, and offer the SSH tunnel route instead.

- Give the user one full tunnel command with -L 8900:127.0.0.1:8900 included, and have them complete setup at http://localhost:8900 in their own browser.

- Skip the InstaBox web desktop and terminal viewers as a setup route, because they failed to connect on a healthy machine during the verified run and a guest reboot did not fix them.

- Verify setup through /healthz afterwards, looking for configured true with the database available and security ok.

## Add CloudDrive2 on the same machine

- Prepare the CloudDrive2 compose and every setting yourself, and have the user paste and run it inside their SSH session, because the container needs privileged mode, the host pid namespace and /dev/fuse, and the direct agent API deployment of it is refused.

- Do not retry the refused direct agent API deployment of that privileged container on a later run.

- Base the compose on the official one with the config folder at /data/home/clouddrive2/Config, the Peach media folder bound as /CloudNAS with shared propagation and the web port bound to 127.0.0.1:19798 only.

- Verify the CloudDrive2 start from the API side before asking the user to log in, checking that the container is up, the loopback port is listening and the web interface answers through the tunnel.

- Have the user register their own CloudDrive2 admin account, log in to 115 inside it and mount only the needed cloud folder such as /115open/云下载 to /CloudNAS/云下载 with auto mount on.

- Reach that console through the tunnel with -L 19799:127.0.0.1:19798 when the user computer already occupies port 19798, and name which install every address belongs to whenever you mention one.

## Make the mount visible inside Peach

- Rewrite the Peach media bind in long syntax with bind propagation set to rshared when the host shows the cloud folder but the Peach container sees an empty directory, and back the compose file up before editing it.

- Recreate the Peach container after the bind change, because a plain restart keeps the old bind.

- Verify the mount with the `verify_cloud_mount_inside_container` skill from inside the Peach container, and never declare it working from a host listing alone.

- Recheck the mount from inside the container after any reboot, and expect later remounts to propagate on their own once the rshared bind is in place.

## Configure the library and read the first scan correctly

- Open configuration through the tunnel at http://localhost:8900 and set the library folder to /media/云下载 with the source CloudDrive 115, normal reading and the relocation mode that keeps existing records.

- Keep the option to scan and enrich metadata after saving turned on, and have the user click save so Peach restarts and starts processing.

- Read progress in the task center, and read a run marked failed with a metadata rate limit error as a partial success when the asset counts show the library actually indexed.

- Verify the outcome from the backend with a read only query of the Peach ledger database plus counts of assets and generated files, instead of asking the user to guess from the interface.

- Tell the user to rerun processing from the task center after the rate limit clears when a small number of items stayed blocked, and skip any re-save.

## Wire the CloudDrive2 download channel

- Connect the Peach container to the CloudDrive2 Docker network and persist that external network in the Peach compose file when address probes from inside Peach all fail, because the two projects start on separate networks and the CloudDrive2 port is loopback only.

- Run `docker compose config --quiet` after every compose edit and keep a dated backup beside the file.

- Fill the CloudDrive2 address in Peach with http://clouddrive2:19798, and never leave it blank because a blank field only probes ports inside the Peach container itself.

- Have the user create the CloudDrive2 API token in the CloudDrive2 web interface with its root directory set to / and with file read, folder creation, system read and the offline download permissions under cloud operations.

- Read the Peach token check error about a missing path as a token root problem, and have the user delete and recreate the token with root / instead of changing Peach fields.

- Fill the 115 target directory with the cloud path of the download folder such as /115open/云下载 and keep the wait limit at 168 hours unless the user asks otherwise.

- Register the library to cloud association in the push discovery card under media library settings, by turning on CloudDrive2 notifications and adding one prefix row that pairs the cloud path /115open/云下载 with the declared 115 media root.

- Skip the webhook configuration Peach generates from that card, because real time push needs a paid CloudDrive2 membership and the library scan picks up landed files without it.

- Accept the channel only when the Peach check reports complete offline permissions, a target directory that can take offline downloads and the remaining 115 offline quota.

- Confirm the saved channel values in the Peach downloads state file under the data folder, checking the stored address, target and wait limit without reading any token value.

- Prove the channel with one real submission, and watch its row in the download_task table move to remote_done and then to ingested.

## Add resource search with Jackett

- Treat code search as an external add on, because Peach ships no built in indexer and queries a Torznab feed instead.

- Deploy linuxserver/jackett through the API with its config at /data/home/jackett/config, the host port bound to 127.0.0.1:9117 and membership in both its own network and the Peach network.

- Probe the Torznab caps path from inside the Peach container and accept an HTTP 200 as reachability, and ignore the HTTP 400 that a bare request to the Jackett root returns.

- Have the user open Jackett through a tunnel with -L 9117:127.0.0.1:9117, add the public Sukebei indexer and copy its Torznab feed.

- Leave the Jackett configuration page at its defaults, and have the user set an admin password only to clear the security banner at the top of the dashboard.

- Verify the Peach side save from the backend by checking that the resource indexers file under the Peach data secrets folder now holds a torznab entry, and treat the Jackett log as the ground truth for whether searches actually run.

- Have the user add the indexer under sources and subscriptions in Peach configuration with the feed host rewritten to jackett:9117, the query string removed, the apikey value moved into the API key field and the indexer enabled.

- Test with a code that has a normal past release before judging the wiring, and confirm Jackett returns results for a manual search before blaming Peach.

- Diagnose an empty result in order, checking the Jackett log for the Torznab search line with its release count first, then running a control search for a known code, and only then questioning the configuration.

- Read zero releases for an unreleased or store limited title as missing content rather than a fault, and cross check the release date and the source site own magnet section before reporting a wiring problem.

- Remind the user that pasting a magnet link into the same dialog bypasses search entirely and works whenever the download channel is configured.

## Keep the access map straight

- Send the user to the public Peach URL for daily use on any network, and reserve the tunnel for configuration pages, the CloudDrive2 console and the Jackett console.

- Explain that closing the tunnel window stops only those local doors, while Peach, CloudDrive2, the mount and any running scan keep working on the machine.

- Name the user own CloudDrive2 on their computer or NAS as a separate install whenever it comes up, because it cannot feed the cloud Peach and its apparent folder size is cloud content seen through its own mount.

- Point phone use at the public URL in the phone browser with an add to home screen shortcut, because Peach publishes desktop builds only and has no official mobile app.

## Match common failures to their fix

- Read a 403 from the setup questions over the public URL as the ADR-0149 local gate, and switch to the tunnel instead of debugging the deployment.

- Read the configuration load failure over the public URL after setup as the same local gate working as designed, and reopen configuration through the tunnel.

- Read an empty cloud folder inside Peach while the host lists files as a bind that predates the mount, and apply the rshared bind fix with a recreate.

- Read the Peach token check error about a missing path in CloudDrive2 as a token rooted below /, and have the user recreate the token with root /.

- Read the banner that the media library is not associated with a cloud directory as a missing push discovery prefix row, and register the prefix before touching the target directory again.

- Read failing address probes from inside Peach in every direction as separate Docker networks, and join the CloudDrive2 network and persist it in the Peach compose file.

- Read zero candidates for one code as a content question first, and check the Jackett log and a control code before changing any configuration.

## Run the acceptance checks before calling it done

- Check /healthz shows configured true, an available database and an online 115 source.

- Check the inside container listing of the mounted cloud folder matches the host count, with one real file read inside the container.

- Check the Peach download channel page reports complete offline permissions, a target that can take offline downloads and the remaining 115 quota.

- Check one real download task in the download_task table has moved through remote_done to ingested.

- Check a control search for a released code returns candidates in the Peach dialog on the user screen, not only in the logs.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Websites

- [Peach on GitHub](https://github.com/peach-mitao/peach) for the upstream docs, reading CLOUDDRIVE.md for mount setup, CLOUDDRIVE_API.md for the download channel, RESOURCE_SEARCH.md for indexers and the ADR documents for the local only setup gate. Fetch the raw files during diagnosis and quote exact field names and error text from them.

## Alternatives for better results

- Offer OpenList as the mount layer instead of CloudDrive2 when a privileged container is impossible, because Peach documents both routes to a local directory.

- Offer Prowlarr instead of Jackett when the user already runs the Servarr stack, because Peach accepts any Torznab feed.