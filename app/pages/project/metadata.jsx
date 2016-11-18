import React from 'react';
import { Link } from 'react-router';

class ProjectMetadataStat extends React.Component {
  render() {
    return (
      <div className="project-metadata-stat">
        <div className="project-metadata-stat__value">{this.props.value}</div>
        <div className="project-metadata-stat__label">{this.props.label}</div>
      </div>
    );
  }
}

ProjectMetadataStat.propTypes = {
  label: React.PropTypes.string.isRequired,
  value: React.PropTypes.string.isRequired,
};

class ProjectMetadata extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      classificationsCount: props.project.classifications_count,
    };
  }

  componentDidMount() {
    if (this.context.pusher) {
      const channel = this.context.pusher.subscribe('panoptes');
      channel.bind('classification', (data) => {
        if (data.project_id === this.props.project.id) {
          this.setState({ classificationsCount: this.state.classificationsCount + 1 });
        }
      });
    }
  }

  componentWillUnmount() {
    if (this.context.pusher) {
      this.context.pusher.unsubscribe('panoptes');
    }
  }

  renderStatus() {
    let percentComplete = 0;
    this.props.activeWorkflows.map((workflow) => {
      percentComplete += workflow.completeness;
    });

    if (this.props.activeWorkflows.length > 0) {
      percentComplete /= this.props.activeWorkflows.length;
    }

    return (
      <div className="project-metadata-status-bar">
        <svg width="100%" height="1em" viewBox="0 0 1 1" preserveAspectRatio="none" style={{ display: 'block' }}>
          <defs>
            <linearGradient id="linear-gradient">
              <stop offset="14%" stopColor="#ff471a" stopOpacity="0%" />
              <stop offset="79%" stopColor="#ffad33" stopOpacity="85%" />
            </linearGradient>
          </defs>
          <rect fill="url(#linear-gradient)" stroke="none" x="0" y="0" width={percentComplete} height="1" />
          <rect fill="hsl(0, 0%, 75%)" stroke="none" x={percentComplete} y="0" width={1 - percentComplete} height="1" />
        </svg>
        <br />
        {Math.floor(percentComplete * 100)}% Complete
      </div>
    );
  }

  render() {
    const project = this.props.project;
    const statsLink = `/projects/${project.slug}/stats`;

    return (
      <div className="project-metadata">
        <div className="project-metadata-header">
          <Link className="project-metadata-header__link" to={statsLink}>
            <span>{project.display_name}{' '}Statistics</span>
          </Link>
        </div>

        {this.renderStatus()}

        <div className="project-metadata-stats">
          <ProjectMetadataStat label="Volunteers" value={project.classifiers_count.toLocaleString()} />
          <ProjectMetadataStat label="Classifications" value={this.state.classificationsCount.toLocaleString()} />
          <ProjectMetadataStat label="Subjects" value={project.subjects_count.toLocaleString()} />
          <ProjectMetadataStat label="Completed Subjects" value={project.retired_subjects_count.toLocaleString()} />
        </div>
      </div>
    );
  }
}

ProjectMetadata.contextTypes = {
  pusher: React.PropTypes.object,
};

ProjectMetadata.propTypes = {
  activeWorkflows: React.PropTypes.array,
  project: React.PropTypes.object.isRequired,
};

ProjectMetadata.defaultProps = {
  activeWorkflows: [],
  project: {},
};

export default ProjectMetadata;
