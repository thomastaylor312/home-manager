# Hammer Meet Nail - The Overuse of CRDs

*Why you should think twice before using CRDs — May 27, 2025*

To be honest, this been brewing for at least 5 years at this point, but a recent job change has finally pushed me to finally write it. As part of my new job, I am much more involved with Kubernetes on a day to day basis after taking a 3 year break from it where I only touched it occasionally. They say that absence makes the heart grow fonder, but if there is one thing where it has absolutely not been the case for me, it is Kubernetes Custom Resource Definitions (CRDs).

For those who may not know me, I've been involved with Kubernetes since 2016 and Docker before that. I was also a long time maintainer of Helm and a co-creator of the [Krustlet](https://krustlet.dev/) project (a rewrite of Kubelet in Rust to support Wasm) in addition to helping build things like Azure Kubernetes Service. I don't say this to brag at all, but I want to make sure people know that this isn't just a random rant from someone on the internet. It comes from a place of deep knowledge and experience.

So with that out of the way, let's dive in:

## Kubernetes has a "seeing everything as a nail" problem

Humans are real good at taking mental shortcuts and that leads many of us being "hammers" that see everything as a nail. We see a screw? Nail it in. Staple? Take a hammer to it. As software engineers, we use many tools, so (at least in my experience) we are more prone to falling into this trap. We see a problem and we think "I can solve this with $INSERT_TOOL because I really like using it and it fits this problem." With that said however, I think Kubernetes users and the community around it are one of the most particularly egregious offenders of this.

Before I continue, I want to be clear: there are many good use cases for Kubernetes and it solved a whole bunch of problems we had in the past. Please don't take away that I hate Kubernetes from this blog post, because I don't. For purposes of this discussion, let's assume you've adopted Kubernetes for a good reason and with a plan. The problem is, once many people adopt Kubernetes, they start trying to put everything in Kubernetes. And I don't mean just running applications on Kubernetes, they try to put every single tool, process, and API in Kubernetes - like a cargo cult on steroids.

Ultimately, people use Kubernetes for everything because they think that is what they're supposed to do once they've adopted it. The dirty secret though is that it often turns out to be a square peg in a round hole and leads to massive underutilization. Talk to any big user of Kubernetes and try to get them to admit their real cluster utilization percentages and you'll see what I mean. Now that, in and of itself, could be a blog post, but I'm not here to talk about that. Kubernetes is a good technology, often a good choice, but once people buy into it, they start to use it for *everything*. And CRDs are one of the principal causes of this problem.

## What are CRDs even for?

When you first hear about CRDs, they seem like a great idea, completely natural as an extension point. From the [Kubernetes docs](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/):

> A custom resource is an extension of the Kubernetes API that is not necessarily available in a default Kubernetes installation. It represents a customization of a particular Kubernetes installation. However, many core Kubernetes functions are now built using custom resources, making Kubernetes more modular.

This is great, right? You need to customize your Kubernetes cluster for your specific needs. It also has the advantage of integrating in to the existing tooling. If you're using CRDs, you can just use `kubectl` to interact with them and then also use all of the other compliance and deployment tools you're using for your containerized applications. Kubernetes' power comes from being a flexible way of running infrastructure and building a platform. This is why building internal developer platforms (IDPs) is all the rage nowadays. CRDs are a natural fit for that. In a perfect world you would define your platform and its CRDs (complete with all the steps like provisioning cloud resources or other steps), then your developers can just specify an image and config and the platform takes care of the rest by creating the CRD. You can also take the example of Ingress/Gateway controllers, which are a great example of using CRDs to extend Kubernetes to handle your specific networking needs by defining additional configuration to extend Kubernetes networking.

The problem here is that people aren't just using them for building platforms or extending Kubernetes functionality. They are using them as some sort of mishmash of One API to Rule Them All and the True Way™ to install any software. I once was working with a customer, and when they spin up a new Kubernetes cluster, they install around 180 CRDs. 180! That is not a platform, that is a mess. Even if we assume a generous number of 10 CRDs per controller, that is 18 different controllers that have to run and take up resources in the cluster, not to even mention the scaling limits you might have depending on how many objects created with those CRDs being stored in the cluster. And it is not just them, I have seen this in many other places as well. People are using CRDs to define everything from their CI/CD pipelines to their internal APIs to their data models. It is like they think that if they can define it in YAML, it should be a CRD.

All of this confuses the purpose of Kubernetes. What are CRDs and Kubernetes even for? Is it to run infrastructure for applications? Is it to be an API server? Is it a storage location? Is it your primary security boundary? That confusion leads to Kubernetes clusters that end up serving one or two of those purposes and then people have a bunch of clusters they're barely using.

## Too Good to be True

Let's break it down some more. Based on what I've seen over the years, here are some of the top ways people use CRDs:

- The primary building block for a developer platform (the example I gave above)
- Data storage for APIs
- The event stream for platform APIs (i.e. controllers)
- Entities for access control
- Configuration
- Leveraging the Kubernetes API to host their own internal APIs
- Managers for other Kubernetes objects via controllers

If that isn't seeing everything as a nail, I don't know what is. It is also a lot of weight for one thing to be bearing.

This reminds me quite a bit of the "too good to be true" or "panacea" problem that shows up in places like naturopathic medicine. Somehow a single essential oil, food, compound, drug, etc. can somehow treat stomach issues, head issues, foot issues, and cure cancer. That is generally a sign it is a fake. I really like this analogy because there honestly might be some possibility that it could help with one of those things (just like how CRDs can help build platforms), but it is highly unlikely it helps with all of them. We have tools for almost every single one of the things mentioned above that are purpose built for handling that specific use case, with its associated tradeoffs depending on your needs.

There are so many problems with this approach that just make me worry. Kubernetes wasn't built to be a solution for all of the things mentioned above. CRDs are great at building/extending a platform, but outside of that they aren't dev friendly and have a *very different* way of handling things like AuthN/Z. They aren't as great as APIs at exposing specific operations because you're basically stuck only using them in a reconcilation loop with eventual consistency (want a request to start a process and stream data back in the response until complete using CRDs? Good luck).

Beyond the technical aspects though, what happens when the next big thing after Kubernetes comes along? Kubernetes is 10 years old at this point. In the tech world, that is ancient, so it is ripe for disruption. If you've depended solely on CRDs, what happens then? ~~I think this is best illustrated by the world of GitOps. Say what you will about GitOps, it is a powerful tool that many users find value in for deploying applications. However, pretty much all of the options out there all depend on Kubernetes and CRDs even if their software might not necessarily be tied directly to Kubernetes. To even use a GitOps tool, you have to have a Kubernetes cluster.~~

**UPDATE (05/28/25): An astute reader pointed out that there is some nuance in the various GitOps tooling options that I don't really want to get into here, especially those that truely are meant for Kubernetes applications. I've left the previous example crossed out and replaced with the new one below**

A great example of this problem in action is the Kro project. It dynamically generates a CRD for every grouping of APIs you want to use in your Kubernetes cluster. Meaning your APIs for *anything* are now dependent on Kubernetes. You also get projects like Cilium, which are fairly powerful and useful in a whole host of networking use cases. But guess what? If you look at all of the installation options in the docs, it is just Kubernetes and more Kubernetes. Even the data store options are CRDs by default. At my previous job, we needed the security benefits of Cilium, but inside of Nomad. So we had to write our own tool (called [Netreap](https://github.com/cosmonic-labs/netreap) if you're curious) to be able to take advantage of it. If I have to already rewrite stuff now in the age of Kubernetes, what is going to happen when the next big thing comes along? You'll have to rewrite to use something else at the cost of a lot of time. This feels like putting handcuffs on yourself when it comes to innovation and flexibility.

## Choosing Wisely

You're probably thinking at this point, "Wow Taylor, that is a lot of ranting, what is the takeaway?"

When I was talking about this with a friend who's been in this space as long as I have, I came up with the saying "Platforms have a lifetime, APIs are eternal." Maybe a bit imprecise (because I know APIs change all the time too), but I think it conveys the point. Platforms are the way we run things, not how we define how our application works. Where we run things changes quite often (location, cloud, containers, VMs, processors, and all sorts of things), but how we interact with our software doesn't change in the same way. So many of us are using APIs that were defined many years ago because they were built for a specific purpose and still work for that purpose, even though we may have first used them when we measured processors in MHz. APIs let you express how a piece of software works in a way that is best for that software, not how it fits into Kubernetes.

Look, I know there's nuance here, and I know there are many caveats with no perfect answers. But can we at least admit that maybe things have gone a bit too far? Here's how I want you to think about it:

**The core rule**: If you have a piece of software that does something only Kubernetes does or actually depends on Kubernetes (i.e. you've built a platform that runs on Kubernetes), then sure, use CRDs. But if it isn't something that only Kubernetes does, then build a normal API and use that instead.

Ask yourself these questions before reaching for CRDs:

- Am I extending Kubernetes itself, or am I just trying to store data/configuration?
- Would this functionality make sense without Kubernetes in the picture?
- Am I building a platform that orchestrates Kubernetes resources, or am I building an application that just happens to run on Kubernetes?
- Will eventual consistency and reconciliation loops actually work for my use case, or do I need synchronous/streaming operations?
- What happens when something newer (or totally different) comes along, does betting on CRDs help, or hurt, my users down the line?

So many promising tools end up handcuffing themselves, or at the very least, take on a pile of unnecessary technical debt, trying to make the round peg of their project fit into the square hole of Kubernetes. I'm not saying you should torch your CRDs, or that using them is always wrong. But for the love of software (and our collective sanity), pause and really *think twice* before reaching for another CRD. A little reflection up front can save a lot of pain later on.

**UPDATE (05/27/25): Clarified the example of 180 CRDs and the conclusion to be more clear about the core rule based on some great feedback I received.**
