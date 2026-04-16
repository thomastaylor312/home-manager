# Nix Revisited

*My thoughts on Nix after 6 months*

I generally like coming back to some of the tools and technologies I have written about before to reevaluate my thoughts as I gain more experience. I have been using Nix for about 6 months now and figured now would be as good a time as any.

When I first wrote about Nix, I listed a bunch of things I'd used Nix for and thought it was useful or warranted more learning. A brief review of those items was:

- Dev Environments being awesome
- Home Manager/Package Management as the best way to manage configuration and packages
- The possibility of using Nix for Monorepos (and by extension, CI/CD)
- Nix being overly complex and lacking documentation
- Nix being very slow to build and test with

I will say that most of my observations have mostly stayed the same, with one major exception. But my options are more nuanced now that I have more experience with Nix and the Nix ecosystem.

## Still Stellar

Using Nix for my development environments (via flakes in particular) has still been the best experience. Even though I've been involved with containers and Kubernetes as part of my job for over 10 years now, using a container for development has always felt clunky on things like a Mac where you're using it through virtualization. When doing things like Rust, that slowness feels even worse. Using Nix with a tool like [direnv](https://direnv.net/), it is a much more pleasant experience.

For example, in my new job, I encountered a project that had a whole set of necessary tools with a special file for pinning those tools to specific versions. Rather than needing to install each of those tools, I specified them all in a roughly 30-line-long `flake.nix` file. No mucking with containers, no installing of tools I don't use outside of that repo, and so on. Really a great tool overall.

Closely related to that is Home Manager. After 6 months, I still have not touched homebrew at all, even as the complexity of my home manager setup has increased. This has remained true even when doing things like adding pinning tools that are not pinned in the Nixpkgs repository or setting up my local AI tools. I got a new computer for my new job and after installing just a few tools that don't work with Home Manager (like Zoom and my browser of choice), I was able to run a single command and get my whole working environment back and ready to go. I cannot recommend the Home Manager project enough.

## Gone Sour

I had previously suggested that I could possibly see Nix being used as the primary build tool for monorepos (and honestly for repos in general). Although I personally will always include a `flake.nix` file that can do a basic build of the project, at this point I will say that for most people, Nix is not the right tool for building and testing a project, especially when using CI/CD tools like GitHub Actions. And for a monorepo, just stay away from it entirely. Them theres fightin' words, so let me explain further.

### Slowness abounds

First and foremost, Nix is just slow. Even with all of my love for Home Manager, if I'm adding something new to my set of tools or doing an upgrade I generally have to download the world (after nixpkgs update). Also, Nix derivations just take a while to evaluate. Locally, it takes me anywhere from 10-30 seconds to get past the evaluation step on to the actual installation process. If you happen to be using any project that doesn't cache (or you haven't configured the cache for it), you also have to account for build times. This problem is only exacerbated when you are using Nix in a CI/CD environment where you often are dealing with slower machines. I work on a lot of Rust projects, which is well-known for taking a while to build and it takes much longer when using Nix.

In the wasmCloud project, for me to run all of the main tests and a full release build, it is 10-15 minutes. Using Nix in our CI/CD pipeline (GitHub Actions) takes over 45 minutes to do the same thing. I'm sure we could speed that up by configuring or tweaking…something. But that is the problem with Nix. You have to know exactly which incantation to use to get things spun up and then forget it by the time you configure it again for another project (in a slightly different way). It just end up being a lot of optimization time for something that is "solved" already in most CI ecosystems. That doesn't mean they are not without their many faults, but they are generally a known quantity and have large ecosystems around them with plugins, extensions, examples, etc.

### Monorepos and building

That leads directly into the monorepo question. If you have any project that contains multiple subprojects (even if it isn't a large monorepo), Nix quickly becomes unwieldy in addition to being slow. This isn't to say you couldn't make it work, but you really would have to start with it in mind from the beginning. Using nix also means you don't have internet access, so e2e tests have to be run separately from the normal unit-style tests (or run in such a way that they run within the "sandbox" of Nix). In wasmCloud, things take forever to run *all the time*. Once again, I already know many different ways we could improve it, but there just isn't time to go try and fix it. Once you fix one thing, then it seems like you have to fix something else to speed up the build which just makes all your Nix files even more difficult to follow along with. Even worse, no matter what we do for improving speed, if *anything* changes in the monorepo—be it a dependency update or a modified file—it often invalidates the entire cache, necessitating a complete rebuild. While solutions like cachix can help mitigate this issue, they add an extra layer of complexity and another attack/security surface to worry about, especially in large projects. and install a project, but I have been very disappointed in the complexity and speed of Nix both in monorepos and as a primary build tool. I know there are projects that have been successful, but, personally speaking, I will not advocate for it as a build tool in my project.

## Wrapping Up

I'm hoping some of this (slightly ranty) feedback can be useful to others out there. I highly recommend people give Nix a try and if you have any additional thoughts, let me know!
