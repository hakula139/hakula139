let
  escape = builtins.replaceStrings [ "&" "\"" "<" ">" ] [ "&amp;" "&quot;" "&lt;" "&gt;" ];
  indent = spaces: builtins.replaceStrings [ "\n" ] [ "\n${spaces}" ];
  picture =
    {
      dark,
      light,
      alt,
      width ? null,
      href ? null,
    }:
    let
      widthAttribute = if width == null then "" else " width=\"${escape (toString width)}\"";
      image = ''
        <picture>
          <source media="(prefers-color-scheme: dark)" srcset="${escape dark}" />
          <img src="${escape light}" alt="${escape alt}"${widthAttribute} />
        </picture>'';
      linked = ''
        <a href="${escape href}">
          ${indent "  " image}
        </a>'';
    in
    if href == null then
      image
    else
      builtins.replaceStrings [ "\n  </picture>\n</a>" ] [ "</picture></a>" ] linked;

  technology =
    {
      icons,
      width,
      perline ? null,
    }:
    let
      ids = builtins.concatStringsSep "%2C" (map (icon: icon.id) icons);
      rows = if perline == null then "" else "&perline=${toString perline}";
      url =
        theme: "https://go-skill-icons.vercel.app/api/icons?i=${ids}${rows}&theme=${theme}&titles=true";
    in
    picture {
      dark = url "dark";
      light = url "light";
      alt = builtins.concatStringsSep ", " (map (icon: icon.label) icons);
      inherit width;
    };

  languages = technology {
    icons = [
      {
        id = "cpp";
        label = "C++";
      }
      {
        id = "rust";
        label = "Rust";
      }
      {
        id = "python";
        label = "Python";
      }
      {
        id = "ts";
        label = "TypeScript";
      }
      {
        id = "go";
        label = "Go";
      }
      {
        id = "nix";
        label = "Nix";
      }
      {
        id = "bash";
        label = "Bash";
      }
    ];
    width = 380;
  };
  stack = technology {
    icons = [
      {
        id = "vue";
        label = "Vue";
      }
      {
        id = "tailwindcss";
        label = "Tailwind CSS";
      }
      {
        id = "nodejs";
        label = "Node.js";
      }
      {
        id = "mysql";
        label = "MySQL";
      }
      {
        id = "duckdb";
        label = "DuckDB";
      }
      {
        id = "mongodb";
        label = "MongoDB";
      }
      {
        id = "redis";
        label = "Redis";
      }
      {
        id = "elasticsearch";
        label = "Elasticsearch";
      }
      {
        id = "cmake";
        label = "CMake";
      }
      {
        id = "docker";
        label = "Docker";
      }
      {
        id = "podman";
        label = "Podman";
      }
      {
        id = "kubernetes";
        label = "Kubernetes";
      }
      {
        id = "nginx";
        label = "Nginx";
      }
      {
        id = "cloudflare";
        label = "Cloudflare";
      }
      {
        id = "github";
        label = "GitHub";
      }
      {
        id = "gitlab";
        label = "GitLab CI/CD";
      }
      {
        id = "prometheus";
        label = "Prometheus";
      }
      {
        id = "grafana";
        label = "Grafana";
      }
    ];
    width = 490;
    perline = 9;
  };
  environment = technology {
    icons = [
      {
        id = "claude";
        label = "Claude";
      }
      {
        id = "chatgpt";
        label = "GPT";
      }
      {
        id = "cursor";
        label = "Cursor";
      }
      {
        id = "nixos";
        label = "Nix / NixOS";
      }
      {
        id = "apple";
        label = "macOS";
      }
    ];
    width = 270;
  };
  snake = picture {
    dark = "https://raw.githubusercontent.com/hakula139/hakula139/output/github-contribution-grid-snake-dark.svg";
    light = "https://raw.githubusercontent.com/hakula139/hakula139/output/github-contribution-grid-snake.svg";
    alt = "A snake eating Hakula's GitHub contribution graph";
    width = "100%";
  };
  trophies = picture {
    dark = "https://github-profile-trophy-hakula.vercel.app/?username=hakula139&theme=darkhub&column=5&no-frame=true&no-bg=true";
    light = "https://github-profile-trophy-hakula.vercel.app/?username=hakula139&theme=flat&column=5&no-frame=true&no-bg=true";
    alt = "Hakula's GitHub trophies";
    href = "https://github.com/ryo-ma/github-profile-trophy";
  };
  stats = picture {
    dark = "https://github-stats.hakula.xyz/api?username=hakula139&theme=github_dark&bg_color=00000000&hide_border=true&show_icons=true&disable_animations=true&count_private=true&card_width=420";
    light = "https://github-stats.hakula.xyz/api?username=hakula139&theme=default&bg_color=00000000&hide_border=true&show_icons=true&disable_animations=true&count_private=true&card_width=420";
    alt = "Hakula's GitHub activity";
    width = 420;
    href = "https://github.com/hakula139?tab=repositories";
  };
  wakatime = picture {
    dark = "https://github-stats.hakula.xyz/api/wakatime?username=Hakula&range=last_7_days&theme=github_dark&bg_color=00000000&hide_border=true&disable_animations=true&layout=compact&langs_count=10&card_width=420&custom_title=This%20week%20I%20spent%20my%20time%20on";
    light = "https://github-stats.hakula.xyz/api/wakatime?username=Hakula&range=last_7_days&theme=default&bg_color=00000000&hide_border=true&disable_animations=true&layout=compact&langs_count=10&card_width=420&custom_title=This%20week%20I%20spent%20my%20time%20on";
    alt = "Hakula's coding activity over the last seven days";
    width = 420;
    href = "https://wakatime.com/@Hakula";
  };
in
builtins.replaceStrings
  [
    "@languages@"
    "@stack@"
    "@environment@"
    "@snake@"
    "@trophies@"
    "@stats@"
    "@wakatime@"
  ]
  [
    languages
    stack
    environment
    snake
    trophies
    (indent "  " stats)
    (indent "  " wakatime)
  ]
  (builtins.readFile ./README.md.in)
